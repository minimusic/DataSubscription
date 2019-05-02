//
//  DataPublisher.swift
//  Subscription
//
//  Created by Chad on 10/9/18.
//  Copyright © 2018 raizlabs. All rights reserved.
//

import Foundation

public struct PublishMessageType: OptionSet {
    // These are subscription types, we could have different, more specific publish messages (e.g. beganLoading)
    // but we'll need a clear way to indicate which messages match which category
    public let rawValue: Int
    // some subscribers may only want a one time access, can use subscriptionBegan, then removed from list?
    public static let subscriptionBegan = PublishMessageType(rawValue: 1 << 0)
    public static let dataMessages = PublishMessageType(rawValue: 1 << 1)
    public static let errorMessages = PublishMessageType(rawValue: 1 << 2)
    public static let loadingMessages = PublishMessageType(rawValue: 1 << 3)
    // redefine allMessages for more than 8 types?
    public static let allMessages = PublishMessageType(rawValue: 127)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public enum PublishError: Swift.Error {
    // Make this a struct to include data, user-facing description
    // Or we could use existing APIError type? Do we need any non-API errors here?
    case noError
    case serverUnreachable
    case invalidResponse
}

public class DataPublisher<Type, Protocol> {
    private var subscribers: [Subscriber] = [Subscriber]()
    // Maybe these properties are read only publicly?
    public var data: [Type] = [Type]()
    public var isLoading: Bool = false
    // do we need an error stack to track multiple errors?
    public var error: PublishError = .noError

    public func updateData(_ newData: [Type]) {
        data = newData
        isLoading = false
        // notify all subscribers
        publish(.dataMessages)
    }

    // Only include add item in subclass for array types?
    public func addItem(_ newItem: Type) {
        data.append(newItem)
        isLoading = false
        // notify all subscribers
        publish(.dataMessages)
    }

    public func beginLoading() {
        // Called for every request
        isLoading = true
        // notify all subscribers
        publish(.loadingMessages)
    }

    public func addError(_ newError: PublishError) {
        // Add new error to stack
        error = newError
        // notify all subscribers
        publish(.errorMessages)
    }

    public func publish(_ message: PublishMessageType) {
        var newSubscribers: [Subscriber] = [Subscriber]()
        for subscriber in subscribers {
            if let validSubscriber = subscriber.weakRef?.value {
                // send message to valid subscriber
                if subscriber.type.contains(message) {
                    // subscriber is interested in this message type
                    self.publish(to: validSubscriber, with: message)
                }
                newSubscribers.append(subscriber)
            }
        }
        subscribers = newSubscribers
    }

    public func publish(to subscriber: Protocol, with message: PublishMessageType) {
        fatalError("DataPublisher subclass must override publish()")
        /* EXAMPLE OVERRIDE:
         override public func publish(to subscriber: ASubscriberProtocol, with message: PublishMessageType) {
         subscriber.publisher(self, sentMessage: message)
         }
         */
    }

    public func subscribe(_ object: Protocol, to messageType: PublishMessageType = .allMessages) {
        // Add to list of subscribers
        // test for duplicates?
        var newSubscriber = Subscriber(object)
        newSubscriber.type = messageType
        subscribers.append(newSubscriber)
        self.publish(to: object, with: .subscriptionBegan)
    }

    public func unsubscribe(_ object: Protocol, to messageType: PublishMessageType = .allMessages) {
        // Remove from list of subscribers
//        var newSubscribers: [Subscriber] = [Subscriber]()
//        for subscriber in subscribers {
//            if let validSubscriber = subscriber.weakRef?.value {
//                // remove message from valid subscriber
//                if validSubscriber === object {
//                    // if any message types remain, keep subscriber
//                    newSubscribers.append(subscriber)
//                }
//            }
//        }
//        subscribers = newSubscribers
    }

    private struct Subscriber {
        // Swift has a bug (SR-55) where it cannot infer that Protocol conforms to AnyObject
        // We have to wrap this so Swift knows that non-objects are handled without 'weak'
        var weakRef: WeakWrapper<Protocol>?
        var type: PublishMessageType = .allMessages
        //var weak weakRef: Protocol?

        init(_ object: Protocol) {
            self.weakRef = WeakWrapper<Protocol>(value: object)
            //self.weakRef = object
        }
    }
}

extension DataPublisher where Protocol: AnyObject {
    private struct testSubscriber {
        var type: PublishMessageType = .allMessages
        weak var weakRef: Protocol?

        init(_ object: Protocol) {
            self.weakRef = object
        }
    }
}

struct WeakWrapper<T> {
    // Work-around to handle Swift bug (SR-55), see "Subscriber" for more
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
