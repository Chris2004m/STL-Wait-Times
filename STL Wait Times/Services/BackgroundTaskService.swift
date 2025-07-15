import Foundation
import BackgroundTasks
import UIKit

/// Service for managing background app refresh tasks
class BackgroundTaskService: ObservableObject {
    static let shared = BackgroundTaskService()
    
    private let backgroundTaskIdentifier = "com.stlwaitline.refresh"
    private let refreshInterval: TimeInterval = 120.0 // 2 minutes as specified in PRD
    
    private init() {}
    
    /// Registers background task types
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    /// Schedules a background app refresh task
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: refreshInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled successfully")
        } catch {
            print("Failed to schedule background refresh: \(error)")
        }
    }
    
    /// Handles the background refresh task
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        print("Background refresh task started")
        
        // Schedule the next refresh
        scheduleBackgroundRefresh()
        
        // Set expiration handler
        task.expirationHandler = {
            print("Background refresh task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform the refresh
        performBackgroundRefresh { success in
            print("Background refresh completed: \(success)")
            task.setTaskCompleted(success: success)
        }
    }
    
    /// Performs the actual background refresh
    private func performBackgroundRefresh(completion: @escaping (Bool) -> Void) {
        let startTime = Date()
        
        // Get facilities with API endpoints
        let facilitiesWithAPIs = FacilityData.facilitiesWithAPIs
        
        guard !facilitiesWithAPIs.isEmpty else {
            completion(true)
            return
        }
        
        // Fetch wait times
        WaitTimeService.shared.fetchAllWaitTimes(facilities: facilitiesWithAPIs)
        
        // Set a timeout for the background task (should complete within 100ms as per PRD)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let elapsed = Date().timeIntervalSince(startTime)
            let success = elapsed <= 0.1 // 100ms limit
            completion(success)
        }
    }
    
    /// Cancels all scheduled background tasks
    func cancelAllBackgroundTasks() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
}

/// Extension for handling app lifecycle
extension BackgroundTaskService {
    
    /// Call this when the app enters the background
    func appDidEnterBackground() {
        scheduleBackgroundRefresh()
    }
    
    /// Call this when the app becomes active
    func appDidBecomeActive() {
        // Refresh immediately if needed (stale data is handled automatically in getBestWaitTime)
        let facilitiesWithAPIs = FacilityData.facilitiesWithAPIs
        if !facilitiesWithAPIs.isEmpty {
            WaitTimeService.shared.fetchAllWaitTimes(facilities: facilitiesWithAPIs)
        }
    }
} 