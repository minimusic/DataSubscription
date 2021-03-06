# DataSubscription
## multi-delegate broadcasting

Delegate protocols allow for tightly coupled communication (between parent/child controllers, controllers/UI, coordinators/controllers, service providers/consumers), but are inherently a one-to-one relationship. In most asynchronous, data-driven flows (requesting remote content) many-to-one communication is needed; this can be handled by a notification system, "listeners" or "observers"(e.g. KVOs), block/closure stores, or specialized caching services.

This `Subscriber` solution is most similar to delegate protocols, but a Publisher can have many delegates and a Subscriber can be the delegate of many puiblishers. An object registers itself as one of a set of "subscribers" to a particular type of data, and then conforms to a single delegate protocol function which will publish the current state of any subscribed data. By using the delegate protocol mechanism it is consistant and familiar with existing iOS/Swift practices and has a strong, typed contract on both sides.

The target use-case is to serve any data that needs to be fetched asynchronously, where the data state will drive the UI. The sample app simulates an endpoint that includes random loading delays and errors to fully demonstrate the flow.

### The intent is to: 
- Make the code easily traceable in both directions (observers, for example, are often invisible from one direction)
- Avoid any "black boxes" (like hidden retention or side effects in NotificationCenter, or KVO magic)
- Avoid blocks (an open door to unexpected retentions, lazy code structure, etc.)
- Enforce types (gcdMulticastDelegate doesn't enforce protocol conformance)
- Formalized structure to avoid mistakes/bugs/oversights
- Simplify implementation and organization of data consumption.
- Find unexpected bugs and limitations in Swift!

## ARCHITECTURE

There are currently three flavors of the Publisher/Subscriber code, each with some advantages and disadvantages.

1 - `GenericPublisher` requires no boilerplate and has strong contracts in both directions. Simply init a `GenericPublisher` instance for the desired data type and it can publish to any object subscribing to the protocol with the matching associated type. This requires some complexity to handle "AnySubscriber" type-erasure, but the complexity is all confined to the generic class. Unfortunately, due to a limitation of Swift, a subscriber can only conform to the protocol once, so one publisher can broadcast to many subscribers, but no object can subscribe to more than one publisher. (One-to-many)

2 - `ExplicitPublisher` allows for strong many-to-many publishing, but requires that an explicit protocol be defined for every publisher, to work around the Swift restrictions on associated types. The Publisher must also be subclassed to properly call that custom delegate protocol. This version has the most boilerplate, which could be handled with code-generation, but still adds verbose code which could expose more opportunities for errors in implementation.

3 - `Publisher` differs from the "Generic" version with a weaker protocol contract. To support many-to-many broadcast, ALL publishers use the same type-less subscriber protocol, so there is no guarantee that the "correct" type is being consumed. Instead, the published data must be tested for type before being consumed. This has the advantages of using generics (easier implementation, less verbose code) but also allows for many-to-many architecture. This also slightly simplifies the type erasure, as only a concrete type is needed to represent the subscriber protocol, but it needn't be type-less.

`Publisher` (number 3) is the current "favorite" balance of compromises, but that could change the three versions (and the Swift language) evolve.

## STATE

A publisher can be in one of four states:

- `.unknown` - The Publisher has been created but has no knowledge of the data yet. It has not yet made an attempt to load the data.
- `.loading` - A request has been made for new data, but the new data has not yet been loaded. The Loading state may include previous but possibly stale data.
- `.loaded` - The publisher has successfully loaded new data (OR could be used for available cached data). Loaded will always include the data (If it is paged data, it could be an incomplete or "mixed" data state, but it is ready to be presented).
- `.error` - An attempt to load the data could not be completed. Error details are included in the state.

This state should always be consumed by each subscriber with an exhaustive switch statement to ensure that all cases are being considered and handled. Ideally, each published data state is mapped to a matching ViewState.

## USAGE

In the example project the `Publisher` instance is created and driven by a manager conforming to the `ManagerProtocol`. The manager serves as the public API for subscribing and requesting data refresh, and is also responsible for calling endpoints/services and defining the type of data published. For now I am only going to describe how to use the final `Publisher` type (third in the list above). First we'll instantiate a `Publisher` in our manager object, and then we'll subscribe to it from the UI and handle a data publication.

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

Here we call `.startLoading()` to enter the `.loading` state when starting the asynchronous request. When we get a response we move to either a `.loaded` state or `.error` state by calling `.updateData()` or `.setError()` on the Publisher. 

To clear/reset the publisher, set it back to the `.unknown` state using `reset()`. This should only be done if the data is dependant on a login state or other external requirement, like in this example implementation of `logout()` in the  `ManagerProtocol`:
```swift
public func logout() {
    publisher.reset()
}
```

### Subscribe to the Publisher

You should only subscribe when you are ready to handle the response as you will get an immediate publication of the current data state when you subscribe (e.g. don't subscribe before your `UITableView` has been created):
```swift
manager.subscribe(self)
```

If you are not using the `ManagerProtocol`, you will need to subscribe directly, wrapping the subscriber with `AnySubscriber()`:
```swift
publisher.subscribe(AnySubscriber(self))
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

There is no default implimentation, but is generally used to clear errors or stale data. It would be overzealous to always refetch the data here (if data is `.loading` or `.loaded`):
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
## GOAL

Seeking feedback to see if there are opportunities to improve any of the three versions of the Publisher type (especially for clarity/readability and ease-of-use), before picking the final architecture. The plan is then to make a single pod/package/framework from the selected version and do a tech study, using it in one or more projects.

### Possible changes/improvements
- Rename `.unknown` state: `.initialized`?
- Merge `Manager` and `Publisher` for flatter architecture?
- Include mechanism for paged data.
- Present system alert for errors in example app.
- Caching? Or keep separate.
- Reduce boilerplate in ExplicitPublisher usage
- Work around one-to-many restriction of GenericPublisher
- Better fix for swift protocol bug in ExplicitPublisher
- Always allow access to "previousData" (make data public, not just associated with`.loading`)?
- Implement hash for GenericSubscribers to avoid errors conforming to hashable (remove hashable requirement).
- A full comparison with other broadcast techniques: Combine, KVO, Notif. Center, Blocks, Multicast Delegate, React, etc.
- Add tests: multiple subscribers, duplicate subscribers, publish data, etc.
- Better name for framework, pub/sub types.
- Allow typesafe publications on background queues or main queue.

A version of this architecture shipped in the Grove app, which includes examples of handling paged data and cached data, but I don't feel either are quite ready for generic usage/application yet.
