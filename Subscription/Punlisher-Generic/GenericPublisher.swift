//
//  NewPublisher.swift
//  Subscription
//
//  Created by Chad on 10/10/18.
//  Copyright © 2018 raizlabs. All rights reserved.
//

import Foundation

public typealias AnyHashable = AnyObject & Hashable

public protocol GenericSubscriberProtocol: AnyHashable {
    associatedtype DataType
    func publication(from publisher: GenericPublisher<DataType>)
}

/// Public type erasing wrapper class
/// Implements the GenericSubscriberProtocol Generic around the associated type
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

    // Initializer takes our concrete implementer of GenericSubscriberProtocol
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
    private var loadedTimestamp: Date?
    /// nil duration means data never becomes stale
    public var staleDuration: TimeInterval?
    public var state: PublisherState = .unknown {
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

// Abstract generic base class that implements GenericSubscriberProtocol
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
            fatalError("_AnyGenSubscriberBase<dataType> instances can not be created, create a subclass instance instead")
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
// Links Concrete.Model (associated type) to _AnyGenSubscriberBase.Model (generic parameter)
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
