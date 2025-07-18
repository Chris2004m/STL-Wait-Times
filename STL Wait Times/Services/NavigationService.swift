//
//  NavigationService.swift
//  STL Wait Times
//
//  Created by Claude AI on 7/18/25.
//

import Foundation
import CoreLocation
import MapboxNavigationCore
import MapboxMaps
import MapboxDirections
import Combine
import MapKit

/// Service for handling navigation route calculation and management
/// Integrates with existing LocationService for seamless navigation experience
@MainActor
class NavigationService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = NavigationService()
    
    // MARK: - Published Properties
    
    @Published var currentRoute: Route?
    @Published var isCalculatingRoute = false
    @Published var navigationError: NavigationError?
    @Published var routeProgress: RouteProgress?
    @Published var estimatedTimeOfArrival: Date?
    @Published var estimatedTravelTime: TimeInterval?
    @Published var remainingDistance: CLLocationDistance?
    
    // MARK: - Private Properties
    
    private let mapboxDirections: Directions
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        // Initialize Mapbox Directions API
        self.mapboxDirections = Directions.shared
        
        // Set up location service observation
        setupLocationServiceObservation()
    }
    
    // MARK: - Route Calculation
    
    /// Calculate route from current location to destination facility
    /// - Parameters:
    ///   - destination: Target facility for navigation
    ///   - profileIdentifier: Routing profile (driving, walking, cycling)
    /// - Returns: Calculated route or nil if calculation fails
    func calculateRoute(
        to destination: Facility,
        profileIdentifier: ProfileIdentifier = .automobile
    ) async -> Route? {
        
        guard let currentLocation = locationService.currentLocation else {
            await MainActor.run {
                self.navigationError = .noLocationAvailable
            }
            return nil
        }
        
        await MainActor.run {
            self.isCalculatingRoute = true
            self.navigationError = nil
        }
        
        do {
            let route = try await performRouteCalculation(
                from: currentLocation.coordinate,
                to: destination.coordinate,
                profileIdentifier: profileIdentifier
            )
            
            await MainActor.run {
                self.currentRoute = route
                self.isCalculatingRoute = false
                self.estimatedTravelTime = route.expectedTravelTime
                self.estimatedTimeOfArrival = Date().addingTimeInterval(route.expectedTravelTime)
                self.remainingDistance = route.distance
            }
            
            return route
            
        } catch {
            await MainActor.run {
                self.navigationError = NavigationError.routeCalculationFailed(error)
                self.isCalculatingRoute = false
            }
            return nil
        }
    }
    
    /// Calculate multiple route alternatives
    /// - Parameters:
    ///   - destination: Target facility for navigation
    ///   - profileIdentifier: Routing profile (driving, walking, cycling)
    /// - Returns: Array of alternative routes
    func calculateAlternativeRoutes(
        to destination: Facility,
        profileIdentifier: ProfileIdentifier = .automobile
    ) async -> [Route] {
        
        guard let currentLocation = locationService.currentLocation else {
            await MainActor.run {
                self.navigationError = .noLocationAvailable
            }
            return []
        }
        
        await MainActor.run {
            self.isCalculatingRoute = true
            self.navigationError = nil
        }
        
        do {
            let routes = try await performAlternativeRouteCalculation(
                from: currentLocation.coordinate,
                to: destination.coordinate,
                profileIdentifier: profileIdentifier
            )
            
            await MainActor.run {
                self.currentRoute = routes.first
                self.isCalculatingRoute = false
                
                if let primaryRoute = routes.first {
                    self.estimatedTravelTime = primaryRoute.expectedTravelTime
                    self.estimatedTimeOfArrival = Date().addingTimeInterval(primaryRoute.expectedTravelTime)
                    self.remainingDistance = primaryRoute.distance
                }
            }
            
            return routes
            
        } catch {
            await MainActor.run {
                self.navigationError = NavigationError.routeCalculationFailed(error)
                self.isCalculatingRoute = false
            }
            return []
        }
    }
    
    // MARK: - Navigation Management
    
    /// Clear current route and navigation state
    func clearRoute() {
        currentRoute = nil
        routeProgress = nil
        estimatedTimeOfArrival = nil
        estimatedTravelTime = nil
        remainingDistance = nil
        navigationError = nil
    }
    
    /// Update route progress during navigation
    /// - Parameter progress: Current route progress from navigation session
    func updateRouteProgress(_ progress: RouteProgress) {
        routeProgress = progress
        
        // Update estimated time of arrival
        let remainingTime = progress.durationRemaining
        estimatedTimeOfArrival = Date().addingTimeInterval(remainingTime)
        estimatedTravelTime = remainingTime
        
        // Update remaining distance
        remainingDistance = progress.distanceRemaining
    }
    
    /// Check if navigation is possible from current location
    /// - Parameter destination: Target facility
    /// - Returns: True if navigation is possible
    func canNavigate(to destination: Facility) -> Bool {
        guard locationService.isLocationEnabled,
              locationService.currentLocation != nil else {
            return false
        }
        
        // Check if destination is valid
        return CLLocationCoordinate2DIsValid(destination.coordinate)
    }
    
    /// Get formatted ETA string
    /// - Returns: Formatted ETA string (e.g., "2:30 PM")
    func getFormattedETA() -> String? {
        guard let eta = estimatedTimeOfArrival else { return nil }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: eta)
    }
    
    /// Get formatted travel time string
    /// - Returns: Formatted travel time string (e.g., "15 min")
    func getFormattedTravelTime() -> String? {
        guard let travelTime = estimatedTravelTime else { return nil }
        
        let minutes = Int(travelTime / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes) min"
        }
    }
    
    /// Get formatted distance string
    /// - Returns: Formatted distance string (e.g., "2.5 mi")
    func getFormattedDistance() -> String? {
        guard let distance = remainingDistance else { return nil }
        
        let distanceFormatter = MKDistanceFormatter()
        distanceFormatter.unitStyle = .abbreviated
        return distanceFormatter.string(fromDistance: distance)
    }
    
    // MARK: - Private Methods
    
    private func setupLocationServiceObservation() {
        // Monitor location changes to update routes if needed
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] _ in
                // Could implement auto-rerouting here if needed
            }
            .store(in: &cancellables)
    }
    
    private func performRouteCalculation(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        profileIdentifier: ProfileIdentifier
    ) async throws -> Route {
        
        return try await withCheckedThrowingContinuation { continuation in
            let waypoints = [
                Waypoint(coordinate: origin),
                Waypoint(coordinate: destination)
            ]
            
            let routeOptions = RouteOptions(waypoints: waypoints, profileIdentifier: profileIdentifier)
            routeOptions.includesSteps = true
            routeOptions.includesAlternativeRoutes = false
            routeOptions.includesSpokenInstructions = true
            routeOptions.includesVisualInstructions = true
            routeOptions.distanceMeasurementSystem = .imperial
            
            let task = mapboxDirections.calculate(routeOptions) { [weak self] result in
                switch result {
                case .success(let response):
                    guard let route = response.routes?.first else {
                        continuation.resume(throwing: NavigationError.noRouteFound)
                        return
                    }
                    continuation.resume(returning: route)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            // Handle task cancellation if needed
            Task {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds timeout
                task.cancel()
                continuation.resume(throwing: NavigationError.routeCalculationTimeout)
            }
        }
    }
    
    private func performAlternativeRouteCalculation(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        profileIdentifier: ProfileIdentifier
    ) async throws -> [Route] {
        
        return try await withCheckedThrowingContinuation { continuation in
            let waypoints = [
                Waypoint(coordinate: origin),
                Waypoint(coordinate: destination)
            ]
            
            let routeOptions = RouteOptions(waypoints: waypoints, profileIdentifier: profileIdentifier)
            routeOptions.includesSteps = true
            routeOptions.includesAlternativeRoutes = true
            routeOptions.includesSpokenInstructions = true
            routeOptions.includesVisualInstructions = true
            routeOptions.distanceMeasurementSystem = .imperial
            
            let task = mapboxDirections.calculate(routeOptions) { [weak self] result in
                switch result {
                case .success(let response):
                    guard let routes = response.routes, !routes.isEmpty else {
                        continuation.resume(throwing: NavigationError.noRouteFound)
                        return
                    }
                    continuation.resume(returning: routes)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            // Handle task cancellation if needed
            Task {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds timeout
                task.cancel()
                continuation.resume(throwing: NavigationError.routeCalculationTimeout)
            }
        }
    }
}

// MARK: - Navigation Error Types

enum NavigationError: LocalizedError, Equatable {
    case noLocationAvailable
    case noRouteFound
    case routeCalculationFailed(Error)
    case routeCalculationTimeout
    case navigationNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .noLocationAvailable:
            return "Location not available. Please enable location services."
        case .noRouteFound:
            return "No route found to the selected facility."
        case .routeCalculationFailed(let error):
            return "Route calculation failed: \(error.localizedDescription)"
        case .routeCalculationTimeout:
            return "Route calculation timed out. Please try again."
        case .navigationNotAvailable:
            return "Navigation is not available at this time."
        }
    }
    
    static func == (lhs: NavigationError, rhs: NavigationError) -> Bool {
        switch (lhs, rhs) {
        case (.noLocationAvailable, .noLocationAvailable),
             (.noRouteFound, .noRouteFound),
             (.routeCalculationTimeout, .routeCalculationTimeout),
             (.navigationNotAvailable, .navigationNotAvailable):
            return true
        case (.routeCalculationFailed(let lhsError), .routeCalculationFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Route Extensions

extension Route {
    /// Get formatted duration string
    var formattedDuration: String {
        let minutes = Int(expectedTravelTime / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes) min"
        }
    }
    
    /// Get formatted distance string
    var formattedDistance: String {
        let distanceFormatter = MKDistanceFormatter()
        distanceFormatter.unitStyle = .abbreviated
        return distanceFormatter.string(fromDistance: distance)
    }
}

// MARK: - RouteProgress Extensions

extension RouteProgress {
    /// Get formatted remaining time string
    var formattedRemainingTime: String? {
        let remainingTime = durationRemaining
        
        let minutes = Int(remainingTime / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes) min"
        }
    }
    
    /// Get formatted remaining distance string
    var formattedRemainingDistance: String {
        let distanceFormatter = MKDistanceFormatter()
        distanceFormatter.unitStyle = .abbreviated
        return distanceFormatter.string(fromDistance: distanceRemaining)
    }
}