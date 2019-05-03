//
//  DataContainer.swift
//  Services
//
//  Created by Chad on 11/26/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import Foundation

public class DataContainer {
    public let manager: Manager
    public let genManager: GenManager
    public let expManager: ExplicitManager

    public init() {
        // All Services

        // All Managers/Publishers
        manager = Manager()
        genManager = GenManager()
        expManager = ExplicitManager()

        // Start up managers
        manager.start(with: self)
        genManager.start(with: self)
        expManager.start(with: self)
    }

    public func logout() {
        manager.logout()
        genManager.logout()
        expManager.logout()
    }
}

public protocol ManagerProtocol {
    associatedtype PublishedType
    var publisher: Publisher<PublishedType> { get }
    /// Give managers a chance to subscribe to other services
    func start(with container: DataContainer)
    /// subscriber is ready to consume: clear errors or stale data if possible
    func refreshIfNeeded()
    /// Clean up any cached data or state
    func logout()

    func subscribe<T: SubscriberProtocol>(_ subscriber: T)
    func unsubscribe<T: SubscriberProtocol>(_ subscriber: T)
}

public extension ManagerProtocol {
    /// Give managers a chance to subscribe to other services
    func start(with container: DataContainer) {}
    /// Clean up any cached data or state
    func logout() {
        publisher.reset()
    }
    /// Wrap AnySubscriber type erasure
    func subscribe<T: SubscriberProtocol>(_ subscriber: T) {
        publisher.subscribe(AnySubscriber(subscriber))
    }
    /// Wrap AnySubscriber type erasure
    func unsubscribe<T: SubscriberProtocol>(_ subscriber: T) {
        publisher.unsubscribe(AnySubscriber(subscriber))
    }
}

public protocol GenManagerProtocol {
    associatedtype PublishedType
    var publisher: GenericPublisher<PublishedType> { get }
    /// Give managers a chance to subscribe to other services
    func start(with container: DataContainer)
    /// subscriber is ready to consume: clear errors or stale data if possible
    func refreshIfNeeded()
    /// Clean up any cached data or state
    func logout()

    func subscribe<T: GenericSubscriberProtocol>(_ subscriber: T) where T.DataType == PublishedType
    func unsubscribe<T: GenericSubscriberProtocol>(_ subscriber: T) where T.DataType == PublishedType
}

public extension GenManagerProtocol {
    /// Give managers a chance to subscribe to other services
    func start(with container: DataContainer) {}
    /// Clean up any cached data or state
    func logout() {
        publisher.reset()
    }
    /// Wrap AnySubscriber type erasure
    func subscribe<T: GenericSubscriberProtocol>(_ subscriber: T) where T.DataType == PublishedType {
        publisher.subscribe(AnyGenSubscriber(subscriber))
    }
    /// Wrap AnySubscriber type erasure
    func unsubscribe<T: GenericSubscriberProtocol>(_ subscriber: T) where T.DataType == PublishedType {
        publisher.unsubscribe(AnyGenSubscriber(subscriber))
    }
}

public protocol ExpManagerProtocol {
    /// Give managers a chance to subscribe to other services
    func start(with container: DataContainer)
    /// subscriber is ready to consume: clear errors or stale data if possible
    func refreshIfNeeded()
    /// Clean up any cached data or state
    func logout()
}

public extension ExpManagerProtocol {
    /// Give managers a chance to subscribe to other services
    func start(with container: DataContainer) {}
}
