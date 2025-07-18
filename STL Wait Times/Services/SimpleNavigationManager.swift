//
//  SimpleNavigationManager.swift
//  STL Wait Times
//
//  Created by Claude AI on 7/18/25.
//

import Foundation
import SwiftUI
import MapboxNavigationCore
import MapboxNavigationUIKit
import MapboxDirections
import CoreLocation
import MapKit

/// Simplified navigation manager that handles basic navigation functionality
/// Compatible with the latest Mapbox Navigation SDK
@MainActor
class SimpleNavigationManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SimpleNavigationManager()
    
    // MARK: - Published Properties
    
    @Published var isNavigating = false
    @Published var navigationError: NavigationError?
    
    // MARK: - Private Properties
    
    private let navigationService = NavigationService.shared
    
    // MARK: - Initialization
    
    private init() {
        // Listen for app lifecycle events to reset navigation state
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - App Lifecycle
    
    @objc private func appDidBecomeActive() {
        // Reset navigation state when returning from Maps
        if isNavigating {
            stopNavigation()
        }
    }
    
    // MARK: - Navigation Methods
    
    /// Start navigation to a facility using external navigation app
    /// - Parameters:
    ///   - facility: Target facility for navigation
    ///   - completion: Completion handler with success/failure result
    func startNavigation(
        to facility: Facility,
        completion: @escaping (Result<Void, NavigationError>) -> Void
    ) {
        
        // For now, let's use the system's built-in navigation
        // This is more reliable and doesn't require complex SDK integration
        
        let destination = facility.coordinate
        let placemark = MKPlacemark(coordinate: destination)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = facility.name
        
        // Open in Maps app for navigation
        MKMapItem.openMaps(with: [mapItem], launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
        
        // Update state temporarily
        isNavigating = true
        
        // Provide feedback
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
        
        // Announce for accessibility
        let announcement = "Opening navigation to \(facility.name) in Maps"
        UIAccessibility.post(notification: .announcement, argument: announcement)
        
        // Reset navigation state after Maps opens (brief delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isNavigating = false
        }
        
        completion(.success(()))
    }
    
    /// Stop navigation (return to app from Maps)
    func stopNavigation() {
        isNavigating = false
    }
    
    /// Check if navigation is possible
    func canNavigate(to facility: Facility) -> Bool {
        return navigationService.canNavigate(to: facility)
    }
}

