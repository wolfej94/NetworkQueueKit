//
//  NetworkReachability.swift
//
//
//  Created by James Wolfe on 13/01/2024.
//

import Network
import Foundation

/// A singleton manager responsible for monitoring network reachability.
internal class NetworkReachabilityManager {
    
    // MARK: - Variables
    static let shared = NetworkReachabilityManager()
    private let monitor = NWPathMonitor()
    private var observerList = ObserverList()
    private(set) var isNetworkAvailable = false

    // MARK: - Initialization
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }

    // MARK: - Actions
    func addObserver(_ observer: NetworkReachabilityObserver) {
        observerList.add(observer)
    }

    func removeObserver(_ observer: NetworkReachabilityObserver) {
        observerList.remove(observer)
    }

    // MARK: - Utilities
    private func notifyObservers() {
        observerList.invoke { observer in
            observer.networkStatusDidChange(isNetworkAvailable)
        }
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            self.isNetworkAvailable = path.status == .satisfied
            self.notifyObservers()
        }

        let queue = DispatchQueue(label: "NetworkReachabilityQueue")
        monitor.start(queue: queue)
    }

    private func stopMonitoring() {
        monitor.cancel()
    }
    
}

/// A protocol for objects interested in receiving network reachability updates.
protocol NetworkReachabilityObserver: AnyObject {
    func networkStatusDidChange(_ isReachable: Bool)
}

/// A private class managing a list of weakly held network reachability observers.
private class ObserverList {
    
    // MARK: - Variables
    private var observers = NSHashTable<AnyObject>.weakObjects()

    // MARK: - ACtions
    func add(_ observer: AnyObject) {
        observers.add(observer)
    }

    func remove(_ observer: AnyObject) {
        observers.remove(observer)
    }
    
    func invoke(_ block: (NetworkReachabilityObserver) -> Void) {
        for observer in observers.allObjects.compactMap({ $0 as? NetworkReachabilityObserver }) {
            block(observer)
        }
    }
    
}
