//
//  Publisher.swift
//  Subscription
//
//  Created by Chad on 10/10/18.
//  Copyright © 2018 raizlabs. All rights reserved.
//

import Foundation

///
/// Any Publisher can publish to the same protocol
///
public protocol SubscriberProtocol: AnyObject {
    func publication(from publisher: AnyPublisher)
}

///
/// Subscribers must be wrapped in AnySubscriber concrete type
///
public class AnySubscriber: SubscriberProtocol, Hashable {

    private weak var base: SubscriberProtocol?

    init(_ base: SubscriberProtocol) {
        self.base = base
    }

    public func hash(into hasher: inout Hasher) {
        if let validSubscriber = base {
            hasher.combine(ObjectIdentifier(validSubscriber))
        }
    }

    public static func == (lhs: AnySubscriber, rhs: AnySubscriber) -> Bool {
        if let leftObject = lhs.base,
            let rightObject = rhs.base {
            return ObjectIdentifier(leftObject) == ObjectIdentifier(rightObject)
        } else {
            return false
        }
    }

    public func publication(from publisher: AnyPublisher) {
        //        base.publication(from: publisher)
        if let validSubscriber = base {
            validSubscriber.publication(from: publisher)
        }
    }

    public func object() -> AnyObject? {
        return base
    }
}

open class AnyPublisher {

}

open class Publisher<Type>: AnyPublisher {
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

    private var subscribers = Set<AnySubscriber>()
    private var loadedTimestamp: Date?
    /// nil duration means data never becomes stale
    public var staleDuration: TimeInterval?
    private(set) public var state: PublisherState = .unknown
    private(set) public var oldData: Type?

    /// Indicates if data should be re-fetched
    public var isStale: Bool {
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

    /// Traceable setter for behavior associated with state changes
    public func setState(_ newState: PublisherState) {
        // preserve old data
        switch state {
        case .loaded(let previousData):
            oldData = previousData
        default:
            break
        }
        // timestamp new data
        switch newState {
        case .loaded:
            loadedTimestamp = Date()
        default:
            break
        }
        // Always publish the new state to all subscribers.
        state = newState
        publish()
    }

    /// Publish state to all subscribers
    public func publish() {
        var newSubscribers = Set<AnySubscriber>()
        for subscriber in subscribers {
            if subscriber.object() != nil {
                // send message to valid subscriber
                self.publish(to: subscriber)
                newSubscribers.insert(subscriber)
            }
        }
        subscribers = newSubscribers
    }

    /// Publish state to one subscriber
    public func publish(to subscriber: AnySubscriber) {
        subscriber.publication(from: self)
    }

    /// Add subscriber to set, publish if new subscriber
    /// Caller must be wrapped: AnySubscriber(self)
    public func subscribe(_ object: AnySubscriber) {
        if subscribers.contains(object) {
            // already subscribed
            // re-publish to duplicate subscriber?
        } else {
            subscribers.insert(object)
            self.publish(to: object)
        }
    }

    /// Remove subscriber from list of subscribers
    /// Caller must be wrapped: AnySubscriber(self)
    public func unsubscribe(_ object: AnySubscriber) {
        subscribers.remove(object)
    }

    /// Called by service to enter .loaded state
    public func updateData(_ newData: Type) {
        setState(.loaded(newData))
    }

    /// Clear all data/state, enter .unknown state
    public func reset() {
        setState(.unknown)
        oldData = nil
    }

    /// Called by service to enter .loading state
    public func startLoading() {
        switch state {
        case .loaded(let staleData):
            setState(.loading(staleData))
        default:
            setState(.loading(nil))
        }
    }

    /// Called by service to enter .error state
    public func setError(_ error: Error) {
        setState(.error(error))    }
}
