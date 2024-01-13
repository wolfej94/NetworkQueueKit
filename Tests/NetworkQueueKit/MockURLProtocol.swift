//
//  MockURLProtocol.swift
//
//
//  Created by James Wolfe on 13/01/2024.
//

import Foundation

class MockURLProtocol: URLProtocol {
    
    // MARK: - Variables
    static var requestHandler: ((URLRequest) -> (HTTPURLResponse, Data))?
    static var registeredURLs: Set<URL> = []

    // MARK: - URLProtocol Methods
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return registeredURLs.contains(url)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("MockURLProtocol.requestHandler not set.")
        }

        let (response, data) = handler(request)
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // No implementation needed for this example
    }
    
}
