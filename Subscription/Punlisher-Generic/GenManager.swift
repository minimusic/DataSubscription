//
//  GenManager.swift
//  Subscription
//
//  Created by Chad on 5/2/19.
//  Copyright © 2019 raizlabs. All rights reserved.
//

import Foundation

public final class GenManager: NSObject {
    public let publisher = GenericPublisher<[DataModel]>()

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

extension GenManager: GenManagerProtocol {
    public func start(with container: ServiceContainer) {
        // Not subscribing to anything
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
