//
//  ContentView.swift
//  STL Wait Times
//
//  Created by Chris Milton on 7/12/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        print("📱 ContentView: Creating view body")
        
        // Main dashboard view (fixed the Mapbox access token issue)
        return DashboardView()
        .onAppear {
            print("✅ ContentView: ContentView appeared")
        }
        .onDisappear {
            print("❌ ContentView: ContentView disappeared")
        }
    }
}

#Preview {
    ContentView()
}
