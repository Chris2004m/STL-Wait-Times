//
//  STL_Wait_TimesApp.swift
//  STL Wait Times
//
//  Created by Chris Milton on 7/12/25.
//

import SwiftUI

@main
struct STL_Wait_TimesApp: App {
    private let backgroundTaskService = BackgroundTaskService.shared
    
    init() {
        // Register background tasks
        backgroundTaskService.registerBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    backgroundTaskService.appDidEnterBackground()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    backgroundTaskService.appDidBecomeActive()
                }
        }
    }
}
