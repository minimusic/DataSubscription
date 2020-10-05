# SubPub

## asynchronous, multi-delegate broadcasting

In asynchronous, data-driven flows (requesting remote content) many-to-one or many-to-many communication is often needed; this can be handled by a notification system, "listeners" or "observers"(e.g. KVOs), block/closure stores, or specialized caching services.

This `Subscriber`/`Publisher` solution is most similar to delegate protocols, but a Publisher can have many delegates/subscribers instead of just one. An object registers itself as one of a set of "subscribers" to a particular type of data, and then conforms to a single delegate protocol function which will receive the current state of any subscribed data. By using the delegate protocol mechanism it is consistant and familiar with existing iOS/Swift practices and has a strong, typed contract on both sides.

## STATE

A publisher can be in one of four states:

- `.unknown` - The Publisher has been created but has no knowledge of the data yet. It has not yet made an attempt to load the data.
- `.loading` - A request has been made for new data, but the new data has not yet been loaded. The Loading state may include previous but possibly stale data.
- `.loaded` - The publisher has successfully loaded new data (OR non-stale cached data). Loaded will always include the data (If it is paged data, it may be an incomplete or "mixed" data state, but it is ready to be presented).
- `.error` - An attempt to load the data could not be completed. Error data is included in the state.

This state should always be consumed by each subscriber with an exhaustive switch statement to ensure that all cases are being considered/handled. Ideally, each published data state is mapped to a matching ViewState.

## USAGE

In the example project the `Publisher` instance is created and driven by a manager conforming to the `ManagerProtocol`. The manager serves as the public API for requesting data refresh, and is also responsible for calling endpoints/services and defining the type of data published. First we'll instantiate a `Publisher` in our manager object, and then we'll subscribe to it from the UI and handle a data publication.

### Create a Publisher

Create and retain a Publisher of the desired type:
```swift
public let publisher = Publisher<[DataModel]>()
```

This means we will be publishing an array of `DataModel` objects/values. In many casses you may need to create a wrapper type to manage the data structure (e.g. if you want to publish two different `String` arrays, you would wrap them in unique types, like `SongNames` and `AlbumNames`, so they can be uniquely published).

When data is fetched, update the Publisher state using convenience functions:
```swift
publisher.startLoading()
DataEndpoint.getShipment() { (response) in
    switch response {
    case .success(let newData):
        self.publisher.updateData(newData)
    case .failure(let error):
        self.publisher.setError(error)
    }
}
```

Here we call `.startLoading()` to enter the `.loading` state when starting the asynchronous request. When we get a resonse we move to either a `.loaded` state or `.error` state but calling `.updateData()` or `.setError()` on the Publisher. 

To clear/reset the publisher, set it back to the `.unknown` state using `reset()`. This should only be done if the data is dependant on a login state or other external requirement, like in this example implementation of `logout()` in the  `ManagerProtocol`:
```swift
public func logout() {
    publisher.reset()
}
```

### Subscribe to the Publisher

You should only subscribe when you are ready to handle the response; you will get an immediate publication of the current data state when you subscribe (e.g. don't subscribe before your `UITableView` has been created):
```swift
publisher.subscribe(self)
```

### Consume publication

Conform to `SubscriberProtocol` and then test for the data types you want to handle. Switch on the publisher's state to handle all cases. It is very bad form to hide any states with a `default` case, except in very rare situations (like a global error handler that subscribes to all publishers, but only handles error states).
```swift
extension PublisherViewController: SubscriberProtocol {
    public func publication(from publisher: AnyPublisher) {
        if let publisher = publisher as? Publisher<[DataModel]> {
            switch publisher.state {
            case .loaded(let newData):
                viewState = .loaded(newData)
            case .error(let theError):
                viewState = .error(theError)
            case .loading:
                // .loading(let oldData) would include any previous data, if available
                viewState = .loading
            case .unknown:
                // Clear out UI as needed if logout is a factor
                break
            }
        }
    }
}
```

If subscribing to multiple publishers, it is common to create separate private functions for the switch.
```swift
extension PublisherViewController: SubscriberProtocol {
    public func publication(from publisher: AnyPublisher) {
        if let productPublisher = publisher as? Publisher<[Product]> {
            handleProductPublication(productPublisher)
        } else if let couponPublisher = publisher as? Publisher<[Coupon]> {
            handleCouponPublication(couponPublisher)
        } else if let locationPublisher = publisher as? Publisher<Location> {
            handleLocationPublication(locationPublisher)
        } else {
            print("Recieved un-handled publication.")
        }
    }
}
```

It is up to the app design to determine when and how often to update the data, or how agressively to recover from error states. Both can be done through the `ManagerProtocol` with `refreshIfNeeded()`. This mechanism can prevent a view getting stuck in an error, but may not be needed if UX properly allows user to manually refresh:
```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // Try to clear any errors when user visits screen
    manager.refreshIfNeeded()
}
```

There is no default implimentation, but it is generally used to clear errors or stale data. It would be overzealous to always refetch the data here (if data is `.loading` or `.loaded`):
```swift
public func refreshIfNeeded() {
    switch publisher.state {
    case .error:
        // refresh if in error state
        getData()
    case .loaded:
        if publisher.isStale {
            getData()
        }
    default:
        break
    }
}
```
