//
//  GenManager.swift
//  Subscription
//
//  Created by Chad on 5/2/19.
//  Copyright © 2019 raizlabs. All rights reserved.
//

import Foundation

public final class GenManager: NSObject {
    // FIXME: replace with generic publisher
    public let publisher = GenericPublisher<[DataModel]>()

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

extension GenManager: GenManagerProtocol {
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
