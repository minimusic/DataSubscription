//
//  TestPublisher.swift
//  
//
//  Created by Chad on 8/27/20.
//

import Foundation
import SubPub

public struct TestData: Equatable {
    var id: String
}

public enum TestError: Swift.Error, Equatable {
    case serviceError
}

public final class TestManager: NSObject {
    public let publisher = Publisher<[TestData]>()

    // Request data and update publisher state
    public func getData() {
        publisher.startLoading()
        testRequest() { (response) in
            switch response {
            case .success(let newData):
                self.publisher.updateData(newData)
            case .failure(let error):
                self.publisher.setError(error)
            }
        }
    }
    
    func testError(_ error: Error) {
        publisher.startLoading()
        self.publisher.setError(error)
    }
    
    func testRequest(completion: @escaping (Result<[TestData],Error>) -> Void) {
        var resultArray = [TestData]()
        for index in 1...10 {
            resultArray.append(TestData(id:"\(index)"))
        }
        completion(.success(resultArray))
    }
}

extension TestManager: ManagerProtocol {
    public func start(with container: AnyObject) {
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
