//
//  DataPublisher.swift
//  Subscription
//
//  Created by Chad on 10/9/18.
//  Copyright © 2018 raizlabs. All rights reserved.
//

import Foundation

public class ExplicitPublisher<Type, Protocol> {
    public enum PublisherState {
        case error(Error)
        case loading(Type?)
        case loaded(Type)
        case unknown
        // .unknown represents that the publisher is initialized
        // but hasn't been told to fetch data yet.
        // This could persist if the publisher is waiting for another event (like login)
        // but should never return to this state until reset/logout.
    }
    private var loadedTimestamp: Date?
    /// nil duration means data never becomes stale
    public var staleDuration: TimeInterval?
    private(set) public var state: PublisherState = .unknown {
        didSet {
            switch state {
            case .error:
                break
            case .loading:
                break
            case .loaded:
                loadedTimestamp = Date()
            case .unknown:
                break
            }
            // Always publish the new state to all subscribers.
            publish()
        }
    }
    
    /// Indicates if data should be re-fetched
    public var isStale: Bool {
        get {
            // Only .loaded data can be stale
            switch state {
            case .loaded:
                if let duration = staleDuration,
                    let staleDate = loadedTimestamp?.addingTimeInterval(duration) {
                    if staleDate < Date() {
                        return true
                    }
                }
            default:
                break
            }
            return false
        }
    }

    // FIXME: refactor explicit subscribers into a Set
    private var subscribers: [Subscriber] = [Subscriber]()

    /// Traceable setter for behavior associated with state changes
    public func setState(_ newState: PublisherState) {
        switch newState {
        case .error:
            break
        case .loading:
            break
        case .loaded:
            loadedTimestamp = Date()
        case .unknown:
            break
        }
        // Always publish the new state to all subscribers.
        state = newState
        publish()
    }

    public func updateData(_ newData: Type) {
        state = .loaded(newData)
    }

    public func startLoading() {
        // Call for every request
        // Includes stale data if available.
        switch state {
        case .loaded(let oldData):
            setState(.loading(oldData))
        default:
            setState(.loading(nil))
        }
    }

    public func setError(_ newError: Error) {
        // Add new error to stack
        setState(.error(newError))
    }

    /// Clear all data/state
    public func reset() {
        setState(.unknown)
    }

    public func publish() {
        var newSubscribers: [Subscriber] = [Subscriber]()
        for subscriber in subscribers {
            if let validSubscriber = subscriber.weakRef?.value {
                // send message to valid subscriber
                self.publish(to: validSubscriber)
                newSubscribers.append(subscriber)
            }
        }
        subscribers = newSubscribers
    }

    public func publish(to subscriber: Protocol) {
        fatalError("ExplicitPublisher subclass must override publish()")
        /* EXAMPLE OVERRIDE:
         override public func publish(to subscriber: SubscriberProtocol, with message: PublishMessageType) {
         subscriber.publisher(self, sentMessage: message)
         }
         */
    }

    public func subscribe(_ object: Protocol) {
        // Add to list of subscribers
        // test for duplicates?
        let newSubscriber = Subscriber(object)
        subscribers.append(newSubscriber)
        self.publish()
    }

    public func unsubscribe(_ object: Protocol) {
        // Remove from list of subscribers
        // FIXME: refactor for subscriber set
    }

    private struct Subscriber {
        // Swift has a bug (SR-55) where it cannot infer that Protocol conforms to AnyObject
        // We have to wrap this so Swift knows that non-objects are handled without 'weak'
        var weakRef: WeakWrapper<Protocol>?
        //var weak weakRef: Protocol?

        init(_ object: Protocol) {
            self.weakRef = WeakWrapper<Protocol>(value: object)
            //self.weakRef = object
        }
    }
}

extension ExplicitPublisher where Protocol: AnyObject {
    private struct testSubscriber {
        weak var weakRef: Protocol?

        init(_ object: Protocol) {
            self.weakRef = object
        }
    }
}

struct WeakWrapper<T> {
    // Work-around to handle Swift bug (SR-55), see "Subscriber" struct for more
    var value: T? {
        if let _obj = _obj {
            // Cast our reference back to the correct type
            // swiftlint:disable:next force_cast
            return (_obj as! T)
        }
        else {
            return _val
        }
    }
    private var _val: T?
    weak private var _obj: AnyObject?

    init(value: T) {
        if value.self is AnyClass {
            // If it is an object, strip the type and hold weak reference
            _obj = value as AnyObject
        }
        else {
            _val = value
        }
    }
}
