//
//  Request.swift
//
//  Created by James Wolfe on 12/01/2024.
//
//

import Foundation
import CoreData

/// Represents a request entity in Core Data.
@objc(Request)
internal class Request: NSManagedObject, Identifiable {
    
    // MARK: - Variables
    /// Returns a fetch request for the `Request` entity.
    @nonobjc class func fetchRequest() -> NSFetchRequest<Request> {
        return NSFetchRequest<Request>(entityName: "Request")
    }

    /// URL of the request.
    @NSManaged var url: URL?

    /// Body of the request.
    @NSManaged var body: Data?

    /// Serialized headers data.
    @NSManaged private var headers: Data?

    /// HTTP method of the request.
    @NSManaged var method: String?

    /// Creation date of the request.
    @NSManaged var createdAt: Date?

    /// Serialized status data.
    @NSManaged private var status: String?
    
    /// Enum representing the status of the request.
    var requestStatus: Status {
        get {
            Status(rawValue: status ?? "") ?? .pending
        }
        set {
            status = newValue.rawValue
        }
    }
    
    /// Dictionary representing the headers of the request.
    var requestHeaders: [String: String] {
        get {
            guard let data = headers else { return [:] }
            return (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: String]) ?? [:]
        }
        set {
            self.headers = try? JSONSerialization.data(withJSONObject: newValue, options: .fragmentsAllowed)
        }
    }
    
    /// Generates a URLRequest from the stored properties.
    var urlRequest: URLRequest? {
        guard let url = url else { return nil }
        var request = URLRequest(url: url)
        request.httpBody = body
        request.allHTTPHeaderFields = requestHeaders
        request.httpMethod = method
        return request
    }
    
}

// MARK: - Request Extension
extension Request {
    
    /// Enum representing the status of a request.
    enum Status: String {
        case pending
        case inProgress
        case cancelled
    }
}
