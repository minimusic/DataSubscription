//
//  Publisher.swift
//  Subscription
//
//  Created by Chad on 10/10/18.
//  Copyright © 2018 raizlabs. All rights reserved.
//

import Foundation

public typealias AnyHashable = AnyObject & Hashable

///
/// Any Publisher can publish to the same protocol
///
public protocol SubscriberProtocol: AnyHashable {
    func publication(from publisher: AnyPublisher)
}

// FIXME: replace type-erasure with flatter concrete type?
public final class AnySubscriber: SubscriberProtocol {
    private let box: _AnySubscriberBase
//    public var hashValue: Int {
//        return box.hashValue
//    }
    public func hash(into hasher: inout Hasher) {
        box.hash(into: &hasher)
    }

    public static func == (lhs: AnySubscriber, rhs: AnySubscriber) -> Bool {
        if let leftObject = lhs.object(), let rightObject = rhs.object() {
            return ObjectIdentifier(leftObject) == ObjectIdentifier(rightObject)
        }
        return false
    }

    // Initializer takes our concrete implementer of SubscriberProtocol
    public init<Concrete: SubscriberProtocol>(_ concrete: Concrete) {
        box = _AnySubscriberBox(concrete)
    }

    public func publication(from publisher: AnyPublisher) {
        box.publication(from: publisher)
    }

    public func object() -> AnyObject? {
        return box.object()
    }
}

private class _AnySubscriberBase: SubscriberProtocol {
//    var hashValue: Int {
//        fatalError("Must override")
//    }
    public func hash(into hasher: inout Hasher) {
        fatalError("Must override")
    }
    static func == (lhs: _AnySubscriberBase, rhs: _AnySubscriberBase) -> Bool {
        if let leftObject = lhs.object(), let rightObject = rhs.object() {
            return ObjectIdentifier(leftObject) == ObjectIdentifier(rightObject)
        }
        return false
    }

    init() {
        guard type(of: self) != _AnySubscriberBase.self else {
            fatalError("_AnyNewSubscriberBase<dataType> instances can not be created, create a subclass instance instead")
        }
    }

    func publication(from publisher: AnyPublisher) {
        fatalError("Must override")
    }

    func object() -> AnyObject? {
        fatalError("Must override")
    }
}

// weak Box class
// final subclass of our abstract base inherits the protocol conformance
// Links Concrete.Model (associated type) to _AnyRowBase.Model (generic parameter)
private final class _AnySubscriberBox<Concrete: SubscriberProtocol>: _AnySubscriberBase {
    // variable used since we're calling mutating functions
    weak var concrete: Concrete?
//    override public var hashValue: Int {
//        return concrete.hashValue
//    }
    override public func hash(into hasher: inout Hasher) {
        concrete.hash(into: &hasher)
    }
    init(_ concrete: Concrete) {
        self.concrete = concrete
    }

    // Trampoline functions forward along to base
    override func publication(from publisher: AnyPublisher) {
        if let validSubscriber = concrete {
            validSubscriber.publication(from: publisher)
        }
    }
    override func object() -> AnyObject? {
        return concrete
    }

}

open class AnyPublisher: NSObject {

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
    public func publish(to subscriber: AnySubscriber) {
        subscriber.publication(from: self)
    }

    /// Add subscriber to set, publish if new subscriber
    public func subscribe(_ object: AnySubscriber) {
        // Add to list of subscribers
        // Caller must be wrapped: AnyNewSubscriber(self)
        if subscribers.contains(object) {
            // re-publish to duplicate subscriber?
        } else {
            subscribers.insert(object)
            self.publish(to: object)
        }
    }

    /// Remove subscriber from set
    public func unsubscribe(_ object: AnySubscriber) {
        // Remove from list of subscribers
        // Caller must be wrapped: AnySubscriber(self)
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
