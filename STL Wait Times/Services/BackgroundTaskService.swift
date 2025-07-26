//
//  BackgroundTaskService.swift
//  STL Wait Times
//
//  Created by Chris Milton on 7/12/25.
//

import Foundation
import BackgroundTasks
import UIKit

class BackgroundTaskService: ObservableObject {
    static let shared = BackgroundTaskService()
    
    private let backgroundTaskIdentifier = "com.stlwaittimes.refresh"
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    private init() {}
    
    func registerBackgroundTasks() {
        // Register background app refresh task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    func appDidEnterBackground() {
        scheduleBackgroundRefresh()
    }
    
    func appDidBecomeActive() {
        endBackgroundTask()
    }
    
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ BackgroundTaskService: Background refresh scheduled")
        } catch {
            print("❌ BackgroundTaskService: Failed to schedule background refresh: \(error)")
        }
    }
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        print("🔄 BackgroundTaskService: Handling background refresh")
        
        // Schedule the next refresh
        scheduleBackgroundRefresh()
        
        // Set expiration handler
        task.expirationHandler = {
            print("⏰ BackgroundTaskService: Background task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform background refresh
        Task {
            // Get Total Access facilities for refresh
            let totalAccessFacilities = FacilityData.allFacilities.filter { 
                $0.id.hasPrefix("total-access") || $0.apiEndpoint != nil 
            }
            
            if !totalAccessFacilities.isEmpty {
                // Refresh wait times in background
                WaitTimeService.shared.fetchAllWaitTimes(facilities: totalAccessFacilities)
                print("✅ BackgroundTaskService: Background refresh completed")
                task.setTaskCompleted(success: true)
            } else {
                print("❌ BackgroundTaskService: No facilities to refresh")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}