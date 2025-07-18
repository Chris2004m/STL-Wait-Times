import Foundation
import BackgroundTasks
import UIKit

/// Service for managing background app refresh tasks
class BackgroundTaskService: ObservableObject {
    static let shared = BackgroundTaskService()
    
    private let backgroundTaskIdentifier = "com.stlwaitline.refresh"
    private let refreshInterval: TimeInterval = 90.0 // 1.5 minutes for more frequent updates
    private let activeRefreshInterval: TimeInterval = 60.0 // 1 minute when app is active
    
    // Active refresh timer for frequent updates when app is active
    private var activeRefreshTimer: Timer?
    
    private init() {}
    
    /// Registers background task types
    func registerBackgroundTasks() {
        print("🔄 BackgroundTaskService: Registering background tasks")
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
        print("✅ BackgroundTaskService: Background tasks registered")
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
        stopActiveRefreshTimer()
    }
    
    /// Call this when the app becomes active
    func appDidBecomeActive() {
        print("🔄 App became active - starting immediate refresh and active timer")
        
        // Refresh immediately if needed (stale data is handled automatically in getBestWaitTime)
        let facilitiesWithAPIs = FacilityData.facilitiesWithAPIs
        if !facilitiesWithAPIs.isEmpty {
            WaitTimeService.shared.fetchAllWaitTimes(facilities: facilitiesWithAPIs)
        }
        
        // Start active refresh timer for frequent updates while app is in use
        startActiveRefreshTimer()
    }
    
    // MARK: - Active Refresh Timer Methods
    
    /// Starts a timer for frequent refreshes while app is active
    private func startActiveRefreshTimer() {
        stopActiveRefreshTimer() // Stop any existing timer first
        
        print("⏰ Starting active refresh timer (every \(activeRefreshInterval) seconds)")
        activeRefreshTimer = Timer.scheduledTimer(withTimeInterval: activeRefreshInterval, repeats: true) { _ in
            print("⏰ Active refresh timer triggered")
            let facilitiesWithAPIs = FacilityData.facilitiesWithAPIs
            if !facilitiesWithAPIs.isEmpty {
                WaitTimeService.shared.fetchAllWaitTimes(facilities: facilitiesWithAPIs)
            }
        }
    }
    
    /// Stops the active refresh timer
    private func stopActiveRefreshTimer() {
        if activeRefreshTimer != nil {
            print("⏰ Stopping active refresh timer")
            activeRefreshTimer?.invalidate()
            activeRefreshTimer = nil
        }
    }
} 