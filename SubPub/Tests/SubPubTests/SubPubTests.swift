import XCTest
@testable import SubPub

final class SubPubTests: XCTestCase {
    static var allTests = [
        ("testSubResponse", testSubResponse),
        ("testMultipleSubscribers", testMultipleSubscribers),
        ("testUnsubscribing", testUnsubscribing),
    ]
    func testSubResponse() {
        let manager = TestManager()
        manager.start(with: self)
        let subscriber = TestSubscriber(manager: manager)
        // Test that subsciber state has updated from publication state
        var publishedData = [TestData]()
        switch manager.publisher.state {
        case .loaded(let PubData):
            publishedData = PubData
        default:
            break
        }
        
        switch subscriber.state {
        case .loaded(let subData):
            XCTAssertEqual(subData, publishedData)
        default:
            XCTFail()
        }
    }
    
    func testMultipleSubscribers() {
        let manager = TestManager()
        manager.start(with: self)
        
        let subscriberA = TestSubscriber(manager: manager)
        let subscriberB = TestSubscriber(manager: manager)
        
        // Test that both subscribers get new publication
        let publishedError: TestError = .serviceError
        manager.testError(publishedError)
        
        switch subscriberA.state {
        case .error(let subError):
            if let subTestError = subError as? TestError {
                XCTAssertEqual(subTestError, publishedError)
            }
            else {
                XCTFail()
            }
        default:
            XCTFail()
        }
        
        switch subscriberB.state {
        case .error(let subError):
            if let subTestError = subError as? TestError {
                XCTAssertEqual(subTestError, publishedError)
            }
            else {
                XCTFail()
            }
        default:
            XCTFail()
        }
        // Better to store bools and have single logical assert at the end?
    }
    
    func testUnsubscribing() {
        let manager = TestManager()
        manager.start(with: self)
        
        let subscriber = TestSubscriber(manager: manager)
        manager.publisher.unsubscribe(subscriber)
        
        var publishedData = [TestData]()
        switch manager.publisher.state {
        case .loaded(let PubData):
            publishedData = PubData
        default:
            break
        }
        
        let publishedError: TestError = .serviceError
        manager.testError(publishedError)
        
        switch subscriber.state {
        case .loaded(let subData):
            XCTAssertEqual(subData, publishedData)
        default:
            XCTFail()
        }
    }
    
    func testSubscriberDeallocated() {
        let manager = TestManager()
        manager.start(with: self)
        
        var subscriberA: TestSubscriber? = TestSubscriber(manager: manager)
        let subscriberB = TestSubscriber(manager: manager)
        
        switch subscriberA!.state {
        case .loaded(_):
            XCTAssert(true)
        default:
            XCTFail()
        }
        // Deallocate the subscriber and make sure the publisher continues to function...
        subscriberA = nil
        
        // Test that remaining subscriber gets new publication
        let publishedError: TestError = .serviceError
        manager.testError(publishedError)
        
        switch subscriberB.state {
        case .error(let subError):
            if let subTestError = subError as? TestError {
                XCTAssertEqual(subTestError, publishedError)
            }
            else {
                XCTFail()
            }
        default:
            XCTFail()
        }
    }
}

