//
//  AppleNavigationService.swift
//  STL Wait Times
//
//  Apple MapKit-based navigation service with route calculation and tracking
//

import Foundation
import MapKit
import Combine
import CoreLocation

/// Apple Maps navigation service for route calculation and turn-by-turn guidance
@MainActor
class AppleNavigationService: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AppleNavigationService()
    
    // MARK: - Published Properties
    
    @Published var currentRoute: MKRoute?
    @Published var currentStep: MKRoute.Step?
    @Published var currentStepIndex: Int = 0
    @Published var distanceToNextStep: CLLocationDistance = 0
    @Published var isNavigating: Bool = false
    @Published var remainingDistance: CLLocationDistance = 0
    @Published var remainingTime: TimeInterval = 0
    
    // MARK: - Private Properties
    
    private var locationManager: CLLocationManager?
    private var destination: CLLocationCoordinate2D?
    private var routePolyline: MKPolyline?
    private var lastLocation: CLLocation?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager?.distanceFilter = 5 // Update every 5 meters
    }
    
    // MARK: - Route Calculation
    
    /// Calculate route to destination
    func calculateRoute(to coordinate: CLLocationCoordinate2D) async throws -> MKRoute {
        guard let userLocation = LocationService.shared.currentLocation else {
            throw AppleNavigationError.noUserLocation
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw AppleNavigationError.noRouteFound
        }
        
        return route
    }
    
    /// Calculate multiple route options
    func calculateRouteOptions(to coordinate: CLLocationCoordinate2D) async throws -> [MKRoute] {
        guard let userLocation = LocationService.shared.currentLocation else {
            throw AppleNavigationError.noUserLocation
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        return response.routes
    }
    
    // MARK: - Navigation Control
    
    /// Start navigation to destination
    func startNavigation(route: MKRoute, destination: CLLocationCoordinate2D) {
        self.currentRoute = route
        self.destination = destination
        self.routePolyline = route.polyline
        self.currentStepIndex = 0
        self.currentStep = route.steps.first
        self.isNavigating = true
        
        // Start location updates
        locationManager?.startUpdatingLocation()
        locationManager?.startUpdatingHeading()
        
        debugLog("🧭 Navigation started with \(route.steps.count) steps")
    }
    
    /// Stop navigation
    func stopNavigation() {
        currentRoute = nil
        currentStep = nil
        currentStepIndex = 0
        destination = nil
        routePolyline = nil
        isNavigating = false
        
        locationManager?.stopUpdatingLocation()
        locationManager?.stopUpdatingHeading()
        
        debugLog("🧭 Navigation stopped")
    }
    
    // MARK: - Route Progress
    
    /// Update navigation progress based on current location
    private func updateNavigationProgress(location: CLLocation) {
        guard let route = currentRoute,
              isNavigating else { return }
        
        // Calculate distance to next step
        if let step = currentStep {
            let stepLocation = CLLocation(
                latitude: step.polyline.coordinate.latitude,
                longitude: step.polyline.coordinate.longitude
            )
            distanceToNextStep = location.distance(from: stepLocation)
            
            // Check if we should advance to next step
            if distanceToNextStep < 20 && currentStepIndex < route.steps.count - 1 {
                advanceToNextStep()
            }
        }
        
        // Calculate remaining distance and time
        remainingDistance = calculateRemainingDistance(from: location, on: route)
        remainingTime = calculateRemainingTime(from: location, on: route)
        
        // Check if destination reached
        if let dest = destination {
            let destLocation = CLLocation(latitude: dest.latitude, longitude: dest.longitude)
            if location.distance(from: destLocation) < 50 {
                destinationReached()
            }
        }
    }
    
    /// Advance to next navigation step
    private func advanceToNextStep() {
        guard let route = currentRoute,
              currentStepIndex < route.steps.count - 1 else { return }
        
        currentStepIndex += 1
        currentStep = route.steps[currentStepIndex]
        
        debugLog("🧭 Advanced to step \(currentStepIndex): \(currentStep?.instructions ?? "")")
    }
    
    /// Called when destination is reached
    private func destinationReached() {
        debugLog("🎉 Destination reached!")
        stopNavigation()
    }
    
    // MARK: - Distance Calculations
    
    private func calculateRemainingDistance(from location: CLLocation, on route: MKRoute) -> CLLocationDistance {
        var remainingDist: CLLocationDistance = 0
        
        // Calculate from current position to end
        for i in currentStepIndex..<route.steps.count {
            remainingDist += route.steps[i].distance
        }
        
        return remainingDist
    }
    
    private func calculateRemainingTime(from location: CLLocation, on route: MKRoute) -> TimeInterval {
        let avgSpeed = location.speed > 0 ? location.speed : 13.4 // Default ~30 mph
        return remainingDistance / avgSpeed
    }
    
    // MARK: - Rerouting
    
    /// Check if user went off route and recalculate if needed
    private func checkAndRerouteIfNeeded(location: CLLocation) async {
        guard let route = currentRoute,
              let destination = destination,
              isNavigating else { return }
        
        let userPoint = MKMapPoint(location.coordinate)
        let closestDistance = distanceToPolyline(point: userPoint, polyline: route.polyline)
        
        // If more than 50 meters off route, recalculate
        if closestDistance > 50 {
            debugLog("🔄 User off route, recalculating...")
            
            do {
                let newRoute = try await calculateRoute(to: destination)
                startNavigation(route: newRoute, destination: destination)
            } catch {
                debugLog("❌ Reroute failed: \(error)")
            }
        }
    }
    
    private func distanceToPolyline(point: MKMapPoint, polyline: MKPolyline) -> CLLocationDistance {
        var minDistance = CLLocationDistance.greatestFiniteMagnitude
        let points = polyline.points()
        
        for i in 0..<polyline.pointCount - 1 {
            let lineStart = points[i]
            let lineEnd = points[i + 1]
            let distance = distanceFromPointToLine(point: point, lineStart: lineStart, lineEnd: lineEnd)
            minDistance = min(minDistance, distance)
        }
        
        return minDistance
    }
    
    private func distanceFromPointToLine(point: MKMapPoint, lineStart: MKMapPoint, lineEnd: MKMapPoint) -> CLLocationDistance {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        
        if dx == 0 && dy == 0 {
            return point.distance(to: lineStart)
        }
        
        let t = ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / (dx * dx + dy * dy)
        let clampedT = max(0, min(1, t))
        
        let closestPoint = MKMapPoint(x: lineStart.x + clampedT * dx, y: lineStart.y + clampedT * dy)
        return point.distance(to: closestPoint)
    }
}

// MARK: - CLLocationManagerDelegate

@MainActor
extension AppleNavigationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        lastLocation = location
        
        if isNavigating {
            updateNavigationProgress(location: location)
            
            // Check for rerouting in background
            Task {
                await checkAndRerouteIfNeeded(location: location)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Heading updates can be used for arrow rotation in UI
    }
}

// MARK: - Navigation Error

enum AppleNavigationError: LocalizedError {
    case noUserLocation
    case noRouteFound
    case calculationFailed
    
    var errorDescription: String? {
        switch self {
        case .noUserLocation:
            return "Unable to determine your current location"
        case .noRouteFound:
            return "No route found to destination"
        case .calculationFailed:
            return "Failed to calculate route"
        }
    }
}

// MARK: - Helper Extensions

extension MKRoute.Step {
    var directionIcon: String {
        let instruction = instructions.lowercased()
        
        if instruction.contains("left") {
            return "arrow.turn.up.left"
        } else if instruction.contains("right") {
            return "arrow.turn.up.right"
        } else if instruction.contains("straight") || instruction.contains("continue") {
            return "arrow.up"
        } else if instruction.contains("arrive") {
            return "mappin.circle.fill"
        } else {
            return "arrow.up"
        }
    }
}
