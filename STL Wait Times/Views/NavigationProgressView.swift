//
//  NavigationProgressView.swift
//  STL Wait Times
//
//  Created by Claude AI on 7/18/25.
//

import SwiftUI
import MapboxNavigationCore

/// A SwiftUI view that shows navigation progress information
struct NavigationProgressView: View {
    let progress: RouteProgress
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            ProgressView(value: progressValue, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 2.0)
            
            // Progress details
            HStack(spacing: 16) {
                // Time remaining
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(progress.formattedRemainingTime ?? "Unknown")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Distance remaining
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(progress.formattedRemainingDistance)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Navigation progress")
        .accessibilityValue("Time remaining: \(progress.formattedRemainingTime ?? "Unknown"), Distance remaining: \(progress.formattedRemainingDistance), \(Int(progressValue * 100))% complete")
    }
    
    /// Calculate progress percentage
    private var progressValue: Double {
        let totalDistance = progress.route.distance
        let remainingDistance = progress.distanceRemaining
        
        guard totalDistance > 0 else { return 0.0 }
        
        let completedDistance = totalDistance - remainingDistance
        return completedDistance / totalDistance
    }
}

// MARK: - Preview

#Preview {
    // Create a mock progress view for preview
    struct MockProgressView: View {
        var body: some View {
            VStack(spacing: 8) {
                ProgressView(value: 0.6, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2.0)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("15 min")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("2.5 mi")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    return MockProgressView()
        .padding()
}