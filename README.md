# DataSubscription
## multi-delegate broadcasting

Delegate protocols allow for tightly coupled communication between architectural layers (parent/child controllers, controllers/UI, coordinators/controllers, service providers/consumers), but is inherently a one-to-one relationship. In any asynchronous, data-driven flow (requesting remote content) there is often a need for many-to-many communication which may be handled by a notification system, "listeners" or "observers"(e.g. KVOs), block/closure stores, or specialized caching services.

This solution is closest to block stores, where an object submits a block to be executed whenever the data updates, but attempts to avoid many hazards of passing blocks (an open door to unexpected retentions, lazy code structure, etc.). Instead, an object simply registers itself as a "subscriber" of a particular type of data, and then conforms to a single delegate protocol function which will publish the current state of that data. Implementation is closer to delegation with protocol, but allows for many delegates.

## GOAL

Seeking feedback to see if there are opportunities to improve any of the three versions of the Publisher type, before picking the final architecture. The plan is then to make a single pod/package/framework from the selected version and do a tech study, using it in one or more projects.

## ARCHITECTURE

There are three distinct flavors of the Publisher/Subscriber code, each with some advantages and disadvantages.

1 - The fully "generic" version requires no boilerplate and has strong contracts in both directions. Simply init an instance for the desired data type and the generic publisher can publish to any object subscribing to the protocol with the matching associated type. This requires some complexity to handle "AnySubscriber" type-erasure, but the complexity is all confined to the generic class. Unfortunately, due to a limitation of Swift, a subscriber can only conform to the protocol once, so one publisher can broadcast to many subscribers, but no object can subscribe to more than one publisher. (One-to-many)

2 - The "explicit" version allows for strong many-to-many publishing, but requires that a unique protocol be defined for every publisher, to work around the Swift restrictions on associated types. The Publisher must also be subclassed to properly call the custom delegate protocol. This is the most boilerplate, which could be handled with code-generation, but still adds verbose code and could expose more opportunities for errors in implementation.

3 - The final version differs from the "Generic" version with a weaker protocol contract. To support many-to-many broadcast, ALL publishers use the same type-less subscriber protocol, so there is no guarantee that the "correct" type is being consumed. Instead, the published data must be tested for type before being consumed. This has the advantages of using generics (easier implementation, less verbose code) but also allows for many-to-many architecture. This also slightly simplifies the type erasure, as only a concrete type is needed to represent the subscriber protocol, but it needn't be type-less.

The third version is the current "favorite" balance of compromises, but that could change as each version (and the Swift language) evolves.

## STATE

Any publisher can be in one of four states: .initialized, .loading, .loaded, .error.

- Initialized - The Publisher has been created but has no knowledge of the data yet. It has not yet made an attempt to load the data.
- Loading - A request has been made for new data, but the new data has not yet been loaded. The Loading state may include previous but possibly stale data.
- Loaded - The publisher has successfully loaded new data, OR there is cached data available. Loaded will always include the data (If it is paged data, it could be an incomplete or "mixed" data state, but ready to be presented).
- Error - An attempt to load the data could not be completed. Error data is included in the state.

This state should always be consumed by each subscriber with an exhaustive switch statement to ensure that all cases are being considered/handled. Ideally, each published data state is mapped to a matching ViewState.

## USAGE

Currently all publisher types are created and managed by a Manager object, though these could likely be merged into a single object in most cases. The manager is the publicly exposed API for subscribing and requesting data refresh, and also responsible for calling endpoints/services and defining the type of data published. For now I am only going to describe how to use the final "Publisher" (Type number 3 above). First we'll instantiate a Publisher in our manager object, and then we'll subscribe to it from the UI and handle a publication of data.

### Create a Publisher

Create and retain a Publisher of the desired type:
```swift
public let publisher = Publisher<[DataModel]>()
```
This means we will be publishing an array of `DataModel` objects/values. In many casses you may need to create a wrapper type to manage the data structure.

When data is fetched, update the Publisher state:
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

To clear/reset the publisher, set it back to the unknown state. This should only be done if the data is dependant on a login state or other external requirement:
```swift
publisher.reset()
```

### Subscribe to the Publisher

You should only subscribe when you are ready to handle the response as you will get an immediate publication of the current data state when you subscribe. In this example, dependancy injection is handle by a global `container` object:
```swift
container.manager.subscribe(self)
```

If you are not using the `ManagerProtocol`, you will need to subscribe directly wrapping `self` with `AnySubscriber`:
```swift
publisher.subscribe(AnySubscriber(self))
```

### Consume publication

Conform to `SubscriberProtocol` and then test for the data types you want to handle. Switch on the publisher's state to handle all cases.

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
