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

    public init() {
        // All Services

        // All Managers/Publishers
        manager = Manager()

        // Start up managers
        manager.start(with: self)
    }

    public func logout() {
        manager.logout()
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
