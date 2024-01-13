# NetworkQueueKit
 Swift package for queuing network requests and processing this queue as a background task or when network reachability improves

# NetworkQueueKit

`NetworkQueueKit` is a Swift library providing a class for managing a queue of network requests, with support for asynchronous processing and background tasks. It also integrates with network reachability to handle requests when the network is available.

##Features

- Asynchronous processing of a queue of network requests.
- Background task support for handling network requests even when the app is in the background.
- Integration with network reachability for responsive handling of network status changes.
##Installation

###Swift Package Manager
Add the following dependency to your Package.swift file:

```
.package(url: "https://github.com/your/repo.git", from: "1.0.0")
```
Then add "NetworkQueueKit" to the dependencies of your target.

##Usage

###Initialization
```
import NetworkQueueKit

// Create an instance of NetworkQueueKit with a custom URLSession (optional)
let networkQueue = NetworkQueueKit(session: yourCustomURLSession)
```
Enqueue a Request
```
let url = URL(string: "https://api.example.com/data")!
let urlRequest = URLRequest(url: url)

do {
    // Enqueue a network request
    try await networkQueue.enqueue(urlRequest: urlRequest)
} catch {
    print("Error enqueuing request: \(error)")
}
```
###Process Queue
```
// Process the queue of pending network requests asynchronously
Task {
    do {
        try await networkQueue.processQueue()
    } catch {
        print("Error processing queue: \(error)")
    }
}
```
##Network Reachability
`NetworkQueueKit` observes changes in network reachability to handle requests accordingly.

##Background Task Support
`NetworkQueueKit` includes background task support to continue processing network requests even when the app is in the background.

##License

`NetworkQueueKit` is released under the MIT License. See LICENSE for details.
