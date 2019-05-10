//
//  ExplicitManager.swift
//  Subscription
//
//  Created by Chad on 5/2/19.
//  Copyright © 2019 raizlabs. All rights reserved.
//

import Foundation

// Boilerplate setup for Explicit Publisher: must subclass to override publish function
public class DataModelPublisher: ExplicitPublisher<[DataModel], ExplicitSubscriber> {
    override public func publish(to subscriber: ExplicitSubscriber) {
        subscriber.publication(from: self)
    }
}

// Boilerplate setup for Explicit Publisher: must set up unique protocol for each publisher
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
