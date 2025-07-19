//
//  NavigationManager.swift
//  STL Wait Times
//
//  Created by Claude AI on 7/18/25.
//

import Foundation
import SwiftUI
import MapboxNavigationCore
import MapboxNavigationUIKit
import MapboxMaps
import MapboxDirections
import CoreLocation
import AVFoundation

/// Manager for handling navigation UI presentation and lifecycle
/// Provides a SwiftUI-friendly interface for Mapbox Navigation
@MainActor
class NavigationManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = NavigationManager()
    
    // MARK: - Published Properties
    
    @Published var isNavigating = false
    @Published var currentNavigationViewController: NavigationViewController?
    @Published var navigationError: NavigationError?
    @Published var routeProgress: RouteProgress?
    
    // MARK: - Private Properties
    
    private let navigationService = NavigationService.shared
    private var navigationMapView: NavigationMapView?
    private var routeResponse: RouteResponse?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Navigation Presentation
    
    /// Start navigation to a facility
    /// - Parameters:
    ///   - facility: Target facility for navigation
    ///   - from: Presenting view controller
    ///   - completion: Completion handler with success/failure result
    func startNavigation(
        to facility: Facility,
        from presentingViewController: UIViewController,
        completion: @escaping (Result<Void, NavigationError>) -> Void
    ) {
        
        Task {
            do {
                // Calculate route using NavigationService
                guard let route = await navigationService.calculateRoute(to: facility) else {
                    completion(.failure(.noRouteFound))
                    return
                }
                
                // Create navigation view controller
                let navigationViewController = try await createNavigationViewController(for: route, to: facility)
                
                // Present navigation
                await MainActor.run {
                    self.currentNavigationViewController = navigationViewController
                    self.isNavigating = true
                    
                    // Present full screen
                    navigationViewController.modalPresentationStyle = .fullScreen
                    presentingViewController.present(navigationViewController, animated: true)
                    
                    completion(.success(()))
                }
                
            } catch {
                completion(.failure(.routeCalculationFailed(error)))
            }
        }
    }
    
    /// Stop current navigation session
    func stopNavigation() {
        guard let navigationViewController = currentNavigationViewController else { return }
        
        navigationViewController.dismiss(animated: true) { [weak self] in
            self?.cleanupNavigation()
        }
    }
    
    /// Check if navigation is currently active
    var isNavigationActive: Bool {
        return isNavigating && currentNavigationViewController != nil
    }
    
    // MARK: - SwiftUI Integration
    
    /// Create a SwiftUI-compatible navigation view controller
    /// - Parameters:
    ///   - route: The route to navigate
    ///   - facility: Target facility
    /// - Returns: Configured NavigationViewController
    private func createNavigationViewController(
        for route: Route,
        to facility: Facility
    ) async throws -> NavigationViewController {
        
        // TODO: Fix NavigationRoutes API compatibility with v3
        // For now, throw error to disable embedded navigation
        throw NavigationError.navigationNotAvailable
    }
    
    /// Configure navigation view controller with custom styling and behavior
    /// - Parameters:
    ///   - navigationViewController: The navigation view controller to configure
    ///   - facility: Target facility
    private func configureNavigationViewController(
        _ navigationViewController: NavigationViewController,
        for facility: Facility
    ) {
        
        // Set custom styling to match app theme
        navigationViewController.view.backgroundColor = .systemBackground
        
        // Configure navigation delegate
        navigationViewController.delegate = self
        
        // Add custom destination annotation
        if let navigationMapView = navigationViewController.navigationMapView {
            addDestinationAnnotation(to: navigationMapView, for: facility)
        }
        
        // Configure voice instructions
        configureVoiceInstructions(for: navigationViewController)
        
        // Store reference to navigation map view
        navigationMapView = navigationViewController.navigationMapView
    }
    
    /// Add custom destination annotation to the map
    /// - Parameters:
    ///   - navigationMapView: The navigation map view
    ///   - facility: Target facility
    private func addDestinationAnnotation(
        to navigationMapView: NavigationMapView,
        for facility: Facility
    ) {
        
        // Create point annotation for the facility
        var pointAnnotation = PointAnnotation(coordinate: facility.coordinate)
        pointAnnotation.image = .init(image: UIImage(systemName: "cross.fill")!, name: "hospital-icon")
        pointAnnotation.iconSize = 1.2
        pointAnnotation.iconAnchor = .bottom
        
        // Add annotation to map
        let pointAnnotationManager = navigationMapView.mapView.annotations.makePointAnnotationManager()
        pointAnnotationManager.annotations = [pointAnnotation]
    }
    
    /// Configure voice instructions for navigation
    /// - Parameter navigationViewController: The navigation view controller
    private func configureVoiceInstructions(for navigationViewController: NavigationViewController) {
        
        // Configure voice controller settings
        // Note: Voice controller API has changed in v3, these properties may not be available
        // Basic voice instructions should work by default
        // TODO: Update with proper v3 voice controller API when available
        
        // For now, we rely on the default voice instructions from Mapbox Navigation SDK
        _ = navigationViewController.voiceController // Silence unused warning
    }
    
    /// Clean up navigation resources
    private func cleanupNavigation() {
        currentNavigationViewController = nil
        navigationMapView = nil
        routeResponse = nil
        isNavigating = false
        routeProgress = nil
        
        // Clear navigation service state
        navigationService.clearRoute()
    }
}

// MARK: - NavigationViewControllerDelegate

extension NavigationManager: @preconcurrency NavigationViewControllerDelegate {
    
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didUpdate progress: RouteProgress,
        with location: CLLocation,
        rawLocation: CLLocation
    ) {
        // Update route progress
        routeProgress = progress
        
        // Update navigation service with progress
        navigationService.updateRouteProgress(progress)
        
        // Provide haptic feedback for maneuvers
        if progress.currentLegProgress.upcomingStep?.maneuverType != .none {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
    
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didArriveAt waypoint: Waypoint
    ) -> Bool {
        // Handle arrival at destination
        // Announce arrival
        let announcement = "You have arrived at your destination"
        UIAccessibility.post(notification: .announcement, argument: announcement)
        
        // Provide completion haptic feedback
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        
        // Auto-dismiss after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.stopNavigation()
        }
        
        return true
    }
    
    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        // Handle navigation dismissal
        cleanupNavigation()
        
        // Provide feedback
        if canceled {
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.warning)
        }
    }
    
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didFailToRerouteWith error: Error
    ) {
        // Handle rerouting failure
        navigationError = .routeCalculationFailed(error)
        
        // Provide error feedback
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.error)
    }
}

// MARK: - SwiftUI Representable

/// SwiftUI representable for NavigationViewController (simplified version)
struct MapboxNavigationView: UIViewControllerRepresentable {
    let facility: Facility
    let onNavigationComplete: () -> Void
    
    @StateObject private var navigationManager = NavigationManager.shared
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Return a placeholder view controller - actual navigation is handled by NavigationManager
        let placeholderVC = UIViewController()
        placeholderVC.view.backgroundColor = .systemBackground
        return placeholderVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Updates handled by NavigationManager
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: MapboxNavigationView
        
        init(_ parent: MapboxNavigationView) {
            self.parent = parent
        }
    }
}

// MARK: - Navigation Helpers

extension NavigationManager {
    
    /// Get the current presenting view controller
    /// - Returns: The topmost view controller
    func getCurrentViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        return window.rootViewController?.topMostViewController()
    }
}

// MARK: - UIViewController Extensions

extension UIViewController {
    
    /// Get the topmost view controller in the hierarchy
    /// - Returns: The topmost view controller
    func topMostViewController() -> UIViewController {
        if let presentedViewController = presentedViewController {
            return presentedViewController.topMostViewController()
        }
        
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController() ?? self
        }
        
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController() ?? self
        }
        
        return self
    }
}