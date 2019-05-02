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
//    public var hashValue: Int {
//        return box.hashValue
//    }
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
        // Caller must be wrapped: AnySubscriber(self)
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

// Abstract generic base class that implements SubscriberProtocol
// Generic parameter around the associated type
private class _AnyGenSubscriberBase<DataType>: GenericSubscriberProtocol {
//    var hashValue: Int {
//        fatalError("Must override")
//    }
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
    override func publication(from publisher: GenericPublisher<DataType>) {
        if let validSubscriber = concrete {
            validSubscriber.publication(from: publisher)
        }
    }
    override func object() -> AnyObject? {
        return concrete
    }

}

//public protocol genericSubscriberProtocol: AnyObject {
//    associatedtype DataType
//    func publication(from publisher: GenericPublisher<DataType>)
//}
//
//// Abstract generic base class that implements genericSubscriberProtocol
//// Generic parameter around the associated type
//private class _AnyGenSubscriberBase<dataType>: genericSubscriberProtocol {
//    init() {
//        guard type(of: self) != _AnyGenSubscriberBase.self else {
//            fatalError("_AnySubscriberBase<dataType> instances can not be created, create a subclass instance instead")
//        }
//    }
//
//    func publication(from publisher: GenericPublisher<dataType>) {
//        fatalError("Must override")
//    }
//
//    func object() -> AnyObject? {
//        fatalError("Must override")
//    }
//}
//
//// weak Box class
//// final subclass of our abstract base
//// Inherits the protocol conformance
//// Links Concrete.Model (associated type) to _AnyRowBase.Model (generic parameter)
//private final class _AnyGenSubscriberBox<Concrete: genericSubscriberProtocol>: _AnyGenSubscriberBase<Concrete.DataType> {
//    // variable used since we're calling mutating functions
//    weak var concrete: Concrete?
//    //var concrete: Concrete
//
//    init(_ concrete: Concrete) {
//        self.concrete = concrete
//    }
//
//    // Trampoline functions forward along to base
//    override func publication(from publisher: GenericPublisher<DataType>) {
//        if let validSubscriber = concrete {
//            validSubscriber.publication(from: publisher)
//        }
////        concrete.publication(from: publisher)
//    }
//    override func object() -> AnyObject? {
//        print("found weak object")
//        return concrete
//    }
//}
//
//// A concrete type to test for _AnySubscriberBox subclass
////public final class TestType<dataType>: genericSubscriberProtocol {
////    public func publication(from publisher: GenericPublisher<dataType>) {
////        // Do nothing
////    }
////}
//
//// Public type erasing wrapper class
//// Implements the genericSubscriberProtocol
//// Generic around the associated type
//public final class AnyGenSubscriber<DataType>: genericSubscriberProtocol {
//    private let box: _AnyGenSubscriberBase<DataType>
//
//    // Initializer takes our concrete implementer of genericSubscriberProtocol
//    init<Concrete: genericSubscriberProtocol>(_ concrete: Concrete) where Concrete.DataType == DataType {
//        box = _AnyGenSubscriberBox(concrete)
//    }
//
//    public func publication(from publisher: GenericPublisher<DataType>) {
//        box.publication(from: publisher)
//    }
//
//    public func object() -> AnyObject? {
////        if let strongBox = box as? _AnySubscriberBox<SubscriberProtocol>{
////            print("found strongBox")
////            return strongBox.object()
////        }
//        return box.object()
//    }
//}
//
//
////// TYPE ERASURE
////// Wraps any genericSubscriberProtocol conformer to this generic type
////public class AnySubscriber<T>: genericSubscriberProtocol {
////    private let _publication: (NewPublisher<T>) -> ()
////    init<U: genericSubscriberProtocol>(_ subscriber: U) where U.dataType == T {
////        _publication = subscriber.publication
////    }
////    public func publication(from publisher: NewPublisher<T>) {
////        _publication(publisher)
////    }
////}
//
//public class GenericPublisher<Type> {
//    private var subscribers = [AnyGenSubscriber<Type>]()
//    // MAYBE: Create a PublishableProtocol to define data init, avoid this optional
//    public var data: Type? = nil
//
//    public func publish() {
//        print("pre publish sub count = \(subscribers.count)")
//        var newSubscribers = [AnyGenSubscriber<Type>]()
//        for subscriber in subscribers {
//            print("Trying a subscriber")
//            if subscriber.object() != nil {
//                print("valid subscriber")
//                // send message to valid subscriber
//                self.publish(to: subscriber)
//                newSubscribers.append(subscriber)
//            } else {
//                print("publish: invalid subscriber")
//            }
//        }
//        subscribers = newSubscribers
//        print("post publish sub count = \(subscribers.count)")
//    }
//
//    public func publish(to subscriber: AnyGenSubscriber<Type>) {
//        subscriber.publication(from: self)
//    }
//
//    public func subscribe(_ object: AnyGenSubscriber<Type>) {
//        print("pre subscribe sub count = \(subscribers.count)")
//        // Add to list of subscribers
//        // Caller must be wrapped: AnySubscriber(self)
//        // test for duplicates?
//        subscribers.append(object)
//        self.publish(to: object)
//        print("post subscribe sub count = \(subscribers.count)")
//    }
//
//    public func unsubscribe(_ object: AnyGenSubscriber<Type>) {
//        print("pre-unsubscribe sub count = \(subscribers.count)")
//        // Remove from list of subscribers
//        // Caller must be wrapped: AnyGenSubscriber(self)
//        var genericSubscribers = [AnyGenSubscriber<Type>]()
//        for subscriber in subscribers {
//            if subscriber.object() != nil {
//                print("valid unsubscriber")
//                // do not include this subscriber in the new array
//                if (subscriber.object() !== object.object()){
//                    print("matching unsubscriber")
//                    genericSubscribers.append(subscriber)
//                }
//            } else {
//                print("invalid unsubscriber")
//            }
//        }
//        subscribers = genericSubscribers
//        print("post unsubscribe sub count = \(subscribers.count)")
//    }
//
////    private struct WeakSubscriber {
////        //weak var weakRef: AnySubscriber<Type>?
////        var weakRef: AnySubscriber<Type>?
////
////        init(_ object: AnySubscriber<Type>) {
////            self.weakRef = object
////        }
////    }
//
//    // Called by service
//    public func updateData(_ newData: Type) {
//        data = newData
//        // notify all subscribers
//        publish()
//    }
//}
