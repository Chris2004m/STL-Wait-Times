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
        print("🚀 STL_Wait_TimesApp: Initializing app")
        
        // Register background tasks
        backgroundTaskService.registerBackgroundTasks()
        
        print("✅ STL_Wait_TimesApp: App initialization complete")
    }
    
    var body: some Scene {
        print("📱 STL_Wait_TimesApp: Creating WindowGroup scene")
        
        return WindowGroup {
            ContentView()
                .onAppear {
                    print("✅ STL_Wait_TimesApp: ContentView appeared")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    print("📱 STL_Wait_TimesApp: App entered background")
                    backgroundTaskService.appDidEnterBackground()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    print("📱 STL_Wait_TimesApp: App became active")
                    backgroundTaskService.appDidBecomeActive()
                }
        }
    }
}
