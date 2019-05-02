//
//  Manager.swift
//  Subscription
//
//  Created by Chad on 4/30/19.
//  Copyright © 2019 raizlabs. All rights reserved.
//

import Foundation

public final class Manager: NSObject {
    public let publisher = Publisher<[DataModel]>()

//    public init() {
//        publisher = NewPublisher<[DataModel]>()
//    }

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
    public func start(with container: DataContainer) {
        // Not subscribing to anything
        getData()
    }

    public func refreshIfNeeded() {
        switch publisher.state {
        case .error:
            // refresh if in error state
            getData()
        default:
            break
        }
    }

    public func logout() {
        publisher.reset()
    }
}
