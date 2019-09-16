//
//  Manager.swift
//  Subscription
//
//  Created by Chad on 4/30/19.
//  Copyright © 2019 raizlabs. All rights reserved.
//

import Foundation
import SubPub

public final class Manager: NSObject {
    public let publisher = Publisher<[DataModel]>()

    /// Request data and update publisher state
    public func getData() {
        publisher.startLoading()
        DataEndpoint.getShipment() { (response) in
            switch response {
            case .success(let newData):
                self.publisher.updateData(newData)
            case .failure(let error):
                self.publisher.setError(error)
            }
        }
    }
}

extension Manager: ManagerProtocol {
    public func start(with container: ServiceContainer) {
        // Subscribe to other publishers here, if needed.
        // For testing, data becomes stale in 60 seconds.
        publisher.staleDuration = 60
        getData()
    }

    public func refreshIfNeeded() {
        switch publisher.state {
        case .error:
            // refresh if in error state
            getData()
        case .loaded:
            if publisher.isStale {
                getData()
            }
        default:
            break
        }
    }

    public func logout() {
        publisher.reset()
    }
}
