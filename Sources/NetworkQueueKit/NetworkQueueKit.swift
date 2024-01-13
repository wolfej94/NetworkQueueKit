//
//  NetworkQueueKit.swift
//
//
//  Created by James Wolfe on 13/01/2024.
//

import Foundation
import UIKit

/// A class representing a queue of network requests.
public class NetworkQueueKit {
    
    // MARK: - Variables
    /// The URLSession used for making network requests.
    let session: URLSession
    
    /// A flag indicating whether the queue is currently processing requests.
    private var processing = false
    
    // MARK: - Initializers
    /// Initializes a new instance of the `NetworkQueueKit` class.
    ///
    /// - Parameter session: The URLSession to be used for making network requests. Defaults to the shared URLSession.
    public init(session: URLSession = .shared) {
        self.session = session
        NetworkReachabilityManager.shared.addObserver(self)
        setupBackgroundTask()
    }
    
    deinit {
        NetworkReachabilityManager.shared.removeObserver(self)
    }
    
    // MARK: - Actions
    /// Enqueues a network request for asynchronous processing.
    ///
    /// - Parameter urlRequest: The URLRequest to be enqueued.
    /// - Throws: An error if enqueuing the request fails.
    public func enqueue(urlRequest: URLRequest) async throws {
        let request: Request = try await QueueData.shared.createObject()
        try await QueueData.shared.updateObject(object: request) {
            $0?.url = urlRequest.url
            $0?.body = urlRequest.httpBody
            $0?.requestHeaders = urlRequest.allHTTPHeaderFields ?? [:]
            $0?.createdAt = Date()
            $0?.requestStatus = Request.Status.pending
            $0?.method = urlRequest.httpMethod
        }
        if NetworkReachabilityManager.shared.isNetworkAvailable {
            try await processQueue()
        }
    }
    
    /// Processes the queue of pending network requests asynchronously.
    ///
    /// - Parameter index: The starting index for processing the queue. Defaults to zero.
    /// - Throws: An error if processing the queue fails.
    public func processQueue(index: Int = .zero) async throws {
        do {
            processing = true
            let requests: [Request] = try await QueueData.shared.fetchObjects(
                predicate: .init(format: "status = %@ ", "pending"),
                sortDescriptors: [
                    .init(key: #keyPath(Request.createdAt), ascending: true)
                ]
            )
            
            guard requests.indices.contains(index), NetworkReachabilityManager.shared.isNetworkAvailable else {
                processing = false
                return
            }
            
            let request = requests[index]
            guard let urlRequest = request.urlRequest else {
                try await QueueData.shared.deleteObject(request)
                try await processQueue(index: index + 1)
                return
            }
            
            try await QueueData.shared.updateObject(object: request) {
                $0?.requestStatus = .inProgress
            }
            
            do {
                let _ = try await session.data(for: urlRequest)
            } catch {
                try await QueueData.shared.updateObject(object: request) {
                    $0?.requestStatus = .pending
                }
            }
            
            try await QueueData.shared.deleteObject(request)
            try await processQueue(index: index + 1)
        } catch {
            processing = false
            throw error
        }
    }
    
    // MARK: - Utilities
    /// Sets up any logic for handling background tasks
    private func setupBackgroundTask() {
        BackgroundTask.registerBackgroundTask()
        
        // Observers for background and foreground app state changes
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            do {
                try BackgroundTask.scheduleAppRefresh()
            } catch {
                print(error)
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            BackgroundTask.cancelAppRefresh()
        }
    }
}

// MARK: - NetworkReachabilityObserver
extension NetworkQueueKit: NetworkReachabilityObserver {
    /// Responds to changes in network reachability.
    ///
    /// - Parameter isReachable: A Boolean value indicating whether the network is reachable.
    func networkStatusDidChange(_ isReachable: Bool) {
        guard UIApplication.shared.applicationState == .active else { return }
        if isReachable {
            Task {
                do {
                    try await processQueue()
                } catch {
                    print(error)
                }
            }
        }
    }
    
}
