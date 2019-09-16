//
//  ManagerProtocol.swift
//  Subscription
//
//  Created by Chad on 9/13/19.
//  Copyright © 2019 raizlabs. All rights reserved.
//

import Foundation

public protocol ManagerProtocol {
    associatedtype PublishedType
    associatedtype ServiceContainerType
    var publisher: Publisher<PublishedType> { get }
    /// Give managers a chance to subscribe to other services
    func start(with container: ServiceContainerType)
    /// subscriber is ready to consume: clear errors or stale data if possible
    func refreshIfNeeded()
    /// Clean up any cached data or state
    func logout()
}

public extension ManagerProtocol {
    /// Give managers a chance to subscribe to other services
    func start(with container: ServiceContainerType) {}
    /// Clean up any cached data or state
    func logout() {
        publisher.reset()
    }
}
