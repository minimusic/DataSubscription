# DataSubscription
multi-delegate broadcasting

Delegate protocols allow for tightly coupled communication between architectural layers (parent/child controllers, controllers/UI, coordinators/controllers, service providers/consumers), but is inherently a one-to-one relationship. In any asynchronous, data-driven flow (requesting remote content) there is often a need for many-to-many communication which may be handled by a notification system, "listeners" or "observers"(e.g. KVOs), block/closure stores, or specialized caching services.

This solution is closest to block stores, where an object submits a block to be executed whenever the data updates, but attempts to avoid many hazards of passing blocks (an open door to unexpected retentions, lazy code structure, etc.). Instead, an object simply registers itself as a "subscriber" of a particular type of data, and then conforms to a single delegate protocol function which will publish the current state of that data. Implementation is closer to delegation with protocol, but allows for many delegates.

ARCHITECTURE
There are three distinct flavors of the Publisher/Subscriber code, each with some advantages and disadvantages.

1 - The fully "generic" version requires no boilerplate and has strong contracts in both directions. Simply init an instance for the desired data type and the generic publisher can publish to any object subscribing to the protocol with the matching associated type. This requires some complexity to handle "AnySubscriber" type-erasure, but the complexity is all confined to the generic class. Unfortunately, due to a limitation of Swift, a subscriber can only conform to the protocol once, so one publisher can broadcast to many subscribers, but no object can subscribe to more than one publisher. (One-to-many)

2 - The "explicit" version allows for strong many-to-many publishing, but requires that a unique protocol be defined for every publisher, to work around the Swift restrictions on associated types. The Publisher must also be subclassed to properly call the custom delegate protocol. This is the most boilerplate, which could be handled with code-generation, but still adds verbose code and could expose more opportunities for errors in implementation.

3 - The final version differs from the "Generic" version with a weaker protocol contract. To support many-to-many broadcast, ALL publishers use the same type-less subscriber protocol, so there is no guarantee that the "correct" type is being consumed. Instead, the published data must be tested for type before being consumed. This has the advantages of using generics (easier implementation, less verbose code) but also allows for many-to-many architecture. This also slightly simplifies the type erasure, as only a concrete type is needed to represent the subscriber protocol, but it needn't be type-less.

The third version is the current "favorite" balance of compromises, but that could change as each version (and the Swift language) evolves.

STATE
Any publisher can be in one of four states: initialized, loading, loaded, error.

Initialized - The Publisher has been created but has no knowledge of the data yet. It has not yet made an attempt to load the data.
Loading - A request has been made for new data, but the new data has not yet been loaded. The Loading state may include previous but possibly stale data.
Loaded - The publisher has successfully loaded new data, OR there is cached data available. Loaded will always include the data (If it is paged data, it could be an incomplete or "mixed" data state, but ready to be presented).
Error - An attempt to load the data could not be completed. Error data is included in the state.

This state should always be consumed by each subscriber with a exhaustive switch statement to ensure all cases are being considered/handled. Ideally, each published data state is mapped to a matching ViewState.
