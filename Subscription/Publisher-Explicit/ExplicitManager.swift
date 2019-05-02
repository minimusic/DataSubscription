//
//  ExplicitManager.swift
//  Subscription
//
//  Created by Chad on 5/2/19.
//  Copyright © 2019 raizlabs. All rights reserved.
//

import Foundation

public class DataModelPublisher: ExplicitPublisher<[DataModel], ExplicitSubscriber> {
    override public func publish(to subscriber: ExplicitSubscriber) {
        subscriber.publication(from: self)
    }
}

public protocol ExplicitSubscriber: AnyObject {
    func publication(from publisher: DataModelPublisher)
}

public final class ExplicitManager: NSObject {
    public let publisher = DataModelPublisher()

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

extension ExplicitManager: ExpManagerProtocol {
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
