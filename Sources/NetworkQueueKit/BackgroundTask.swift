//
//  BackgroundTask.swift
//
//
//  Created by James Wolfe on 13/01/2024.
//

import BackgroundTasks

/// A utility class for managing background tasks.
internal class BackgroundTask {
    
    // MARK: - Variables
    /// The identifier for the background task.
    static let taskIdentifier = "com.wolfe.queue.processQueueTask"

    // MARK: - Actions
    /// Registers the background task.
    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    /// Cancels the background task.
    static func cancelAppRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
    }

    /// Schedules the background task for app refresh.
    static func scheduleAppRefresh() throws {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60) // 5 minutes from now

        try BGTaskScheduler.shared.submit(request)
    }

    // MARK: - Utilities
    /// Handles the execution of the background app refresh task.
    private static func handleAppRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            let queue = NetworkQueueKit()
            try? await queue.processQueue()

            task.setTaskCompleted(success: true)
        }
    }
    
}
