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
        
        // Perform background refresh
        var didCompleteTask = false
        
        task.expirationHandler = {
            if !didCompleteTask {
                print("⏰ BackgroundTaskService: Background task expired")
                didCompleteTask = true
                task.setTaskCompleted(success: false)
            }
        }
        
        let totalAccessFacilities = FacilityData.allFacilities.filter {
            $0.id.hasPrefix("total-access") || $0.apiEndpoint != nil
        }
        
        guard !totalAccessFacilities.isEmpty else {
            print("❌ BackgroundTaskService: No facilities to refresh")
            if !didCompleteTask {
                didCompleteTask = true
                task.setTaskCompleted(success: false)
            }
            return
        }
        
        WaitTimeService.shared.fetchAllWaitTimes(facilities: totalAccessFacilities) { result in
            guard !didCompleteTask else { return }
            didCompleteTask = true
            
            switch result {
            case .success:
                print("✅ BackgroundTaskService: Background refresh completed")
                task.setTaskCompleted(success: true)
            case .failure(let error):
                print("❌ BackgroundTaskService: Refresh failed with error: \(error.localizedDescription)")
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