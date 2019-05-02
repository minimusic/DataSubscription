//
//  NewPublisher.swift
//  Subscription
//
//  Created by Chad on 10/10/18.
//  Copyright © 2018 raizlabs. All rights reserved.
//

import Foundation

public protocol GenericSubscriberProtocol: AnyHashable {
    associatedtype DataType
    func publication(from publisher: GenericPublisher<DataType>)
}

/// Public type erasing wrapper class
/// Implements the SubscriberProtocol Generic around the associated type
public final class AnyGenSubscriber<DataType>: GenericSubscriberProtocol {
    private let box: _AnyGenSubscriberBase<DataType>

    public func hash(into hasher: inout Hasher) {
        box.hash(into: &hasher)
    }

    public static func == (lhs: AnyGenSubscriber<DataType>, rhs: AnyGenSubscriber<DataType>) -> Bool {
        if let leftObject = lhs.object(), let rightObject = rhs.object() {
            return ObjectIdentifier(leftObject) == ObjectIdentifier(rightObject)
        }
        return false
    }

    // Initializer takes our concrete implementer of SubscriberProtocol
    public init<Concrete: GenericSubscriberProtocol>(_ concrete: Concrete) where Concrete.DataType == DataType {
        box = _AnyGenSubscriberBox(concrete)
    }

    public func publication(from publisher: GenericPublisher<DataType>) {
        box.publication(from: publisher)
    }

    public func object() -> AnyObject? {
        return box.object()
    }
}

open class GenericPublisher<Type>: NSObject {
    public enum PublisherState {
        case error(Error)
        case loading(Type?)
        case loaded(Type)
        case unknown
    }

    private var subscribers = Set<AnyGenSubscriber<Type>>()
    public var state: PublisherState = .unknown {
        didSet {
            publish()
        }
    }

    /// Publish state to all subscribers
    public func publish() {
        for subscriber in subscribers {
            if subscriber.object() != nil {
                // send message to valid subscriber
                self.publish(to: subscriber)
            } else {
                subscribers.remove(subscriber)
            }
        }
    }

    /// Publish state to one subscriber
    public func publish(to subscriber: AnyGenSubscriber<Type>) {
        subscriber.publication(from: self)
    }

    /// Add subscriber to set, publish if new subscriber
    public func subscribe(_ object: AnyGenSubscriber<Type>) {
        // Add to list of subscribers
        // Caller must be wrapped: AnyGenSubscriber(self)
        if subscribers.contains(object) {
            // re-publish to duplicate subscriber?
        } else {
            subscribers.insert(object)
            self.publish(to: object)
        }
    }

    /// Remove subscriber from set
    public func unsubscribe(_ object: AnyGenSubscriber<Type>) {
        // Remove from list of subscribers
        // Caller must be wrapped: AnyGenSubscriber(self)
        subscribers.remove(object)
    }

    /// Called by service to update state
    public func updateData(_ newData: Type) {
        state = .loaded(newData)
    }

    /// Clear all data/state
    public func reset() {
        state = .unknown
    }

    public func startLoading() {
        switch state {
        case .loaded(let staleData):
            state = .loading(staleData)
        default:
            state = .loading(nil)
        }
    }

    public func setError(_ error: Error) {
        state = .error(error)
    }
}

// Abstract generic base class that implements SubscriberProtocol
// Generic parameter around the associated type
private class _AnyGenSubscriberBase<DataType>: GenericSubscriberProtocol {
    public func hash(into hasher: inout Hasher) {
        fatalError("Must override")
    }
    static func == (lhs: _AnyGenSubscriberBase<DataType>, rhs: _AnyGenSubscriberBase<DataType>) -> Bool {
        if let leftObject = lhs.object(), let rightObject = rhs.object() {
            return ObjectIdentifier(leftObject) == ObjectIdentifier(rightObject)
        }
        return false
    }

    init() {
        guard type(of: self) != _AnyGenSubscriberBase.self else {
            fatalError("_AnySubscriberBase<dataType> instances can not be created, create a subclass instance instead")
        }
    }

    func publication(from publisher: GenericPublisher<DataType>) {
        fatalError("Must override")
    }

    func object() -> AnyObject? {
        fatalError("Must override")
    }
}

// weak Box class
// final subclass of our abstract base inherits the protocol conformance
// Links Concrete.Model (associated type) to _AnyRowBase.Model (generic parameter)
private final class _AnyGenSubscriberBox<Concrete: GenericSubscriberProtocol>: _AnyGenSubscriberBase<Concrete.DataType> {
    // variable used since we're calling mutating functions
    weak var concrete: Concrete?

    override public func hash(into hasher: inout Hasher) {
        concrete.hash(into: &hasher)
    }
    init(_ concrete: Concrete) {
        self.concrete = concrete
    }

    // Trampoline functions forward along to base
    override func publication(from publisher: GenericPublisher<DataType>) {
        if let validSubscriber = concrete {
            validSubscriber.publication(from: publisher)
        }
    }
    override func object() -> AnyObject? {
        return concrete
    }

}
