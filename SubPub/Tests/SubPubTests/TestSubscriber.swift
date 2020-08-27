//
//  TestSubscriber.swift
//  
//
//  Created by Chad on 8/27/20.
//

import Foundation
import SubPub

class TestSubscriber: NSObject {
    public enum TestState {
        case error(Error)
        case loading
        case loaded([TestData])
    }
    public var state: TestState = .loading
    private let manager: TestManager
    
    // MARK: - Init

    init(manager: TestManager) {
        self.manager = manager
        super.init()
        manager.publisher.subscribe(self)
    }

    @objc func refreshData() {
        manager.getData()
    }
}

// MARK: - SubscriberProtocol

/// Recieve data state publication and convert to local view state
/// setting the view state should refresh UI appropriately
extension TestSubscriber: SubscriberProtocol {
    public func publication(from publisher: AnyPublisher) {
        if let publisher = publisher as? Publisher<[TestData]> {
            switch publisher.state {
            case .loaded(let newData):
                state = .loaded(newData)
            case .error(let theError):
                state = .error(theError)
            case .loading:
                state = .loading
            case .unknown:
                state = .loading
            }
        } else {
            print("Recieved un-handled publication.")
        }
    }
}
