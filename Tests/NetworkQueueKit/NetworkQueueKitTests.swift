import XCTest
import Foundation
import CoreData
@testable import NetworkQueueKit

class NetworkQueueKitTests: XCTestCase {
    
    // MARK: - Test Variables
    var testQueue: NetworkQueueKit!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        // Set up the test queue with a mock URLSession
        let configuration = URLSessionConfiguration.ephemeral
        URLProtocol.registerClass(MockURLProtocol.self)
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)
        
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Request")
        let delete = NSBatchDeleteRequest(fetchRequest: fetch)
        _ = try? QueueData.shared.mainContext.execute(delete)
        
        testQueue = NetworkQueueKit(session: mockSession)
    }

    override func tearDown() {
        super.tearDown()
        URLProtocol.unregisterClass(MockURLProtocol.self)
        testQueue = nil
    }

    // MARK: - Test Cases
    func testEnqueueRequest() async throws {
        let url = URL(string: "https://example.com")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Mock a successful network response
        MockURLProtocol.registeredURLs = [URL(string: "https://example.com")!]
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        do {
            // Enqueue the request
            try await testQueue.enqueue(urlRequest: request)
            
            // Ensure the request is in the pending state
            let requests = try await QueueData.shared.fetchObjects() as [Request]
            XCTAssertEqual(requests.count, 1)
            XCTAssertEqual(requests.first?.requestStatus, .pending)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testProcessQueue() async throws {
        // Mock a network response
        MockURLProtocol.registeredURLs = [URL(string: "https://example.com")!]
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        let url = URL(string: "https://example.com")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Mock a pending request in the data store
        try await testQueue.enqueue(urlRequest: request)
        
        do {
            // Process the queue
            try await testQueue.processQueue()
            
            // Ensure the request is processed and removed from the data store
            let requests = try await QueueData.shared.fetchObjects() as [Request]
            XCTAssertEqual(requests.count, 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
}
