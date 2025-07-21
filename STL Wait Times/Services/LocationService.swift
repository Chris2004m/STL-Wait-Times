import Foundation
import CoreLocation
import MapKit
import Combine

/// Service for managing user location and geo-fencing
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled = false
    @Published var locationError: LocationError?
    @Published var isNearFacility: [String: Bool] = [:]
    @Published var isLoadingLocation = false
    @Published var hasInitialLocation = false
    
    // MARK: - Driving Time Properties
    @Published var drivingTimes: [String: TimeInterval] = [:] // facilityId -> seconds
    @Published var isDrivingTimeLoading: Set<String> = [] // Track loading state per facility
    private var drivingTimeCache: [String: (time: TimeInterval, timestamp: Date)] = [:]
    private let drivingTimeCacheExpiry: TimeInterval = 3600 // 1 hour cache
    
    private let geoFenceRadius: CLLocationDistance = 75.0 // 75 meters as specified in PRD
    private let geoFenceMinTime: TimeInterval = 5 * 60 // 5 minutes
    private var geoFenceTimers: [String: Timer] = [:]
    
    override init() {
        super.init()
        print("📍 DEBUG: LocationService initializing...")
        setupLocationManager()
        requestLocationPermissionIfNeeded()
        print("📍 DEBUG: LocationService initialized")
    }
    
    private func setupLocationManager() {
        print("📍 DEBUG: Setting up location manager...")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0 // Update every 10 meters
        
        authorizationStatus = locationManager.authorizationStatus
        isLocationEnabled = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        
        print("📍 DEBUG: Location setup complete - Status: \(authorizationStatus.rawValue), Enabled: \(isLocationEnabled)")
    }
    
    /// Requests location permission from user
    func requestLocationPermission() {
        print("📍 DEBUG: requestLocationPermission called - current status: \(authorizationStatus.rawValue)")
        switch authorizationStatus {
        case .notDetermined:
            print("📍 DEBUG: Requesting location permission...")
            isLoadingLocation = true
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("📍 DEBUG: Location permission denied/restricted")
            locationError = .permissionDenied
            isLoadingLocation = false
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 DEBUG: Location permission already granted, starting location updates")
            startLocationUpdates()
        @unknown default:
            print("📍 DEBUG: Unknown location permission status")
            locationError = .unknown
            isLoadingLocation = false
        }
    }
    
    /// Automatically requests location permission if not yet determined
    private func requestLocationPermissionIfNeeded() {
        print("📍 DEBUG: requestLocationPermissionIfNeeded called")
        print("📍 DEBUG: authorizationStatus: \(authorizationStatus.rawValue), isLocationEnabled: \(isLocationEnabled), currentLocation: \(currentLocation?.description ?? "nil")")
        
        if authorizationStatus == .notDetermined {
            print("📍 DEBUG: Authorization not determined, requesting permission")
            requestLocationPermission()
        } else if isLocationEnabled && currentLocation == nil {
            print("📍 DEBUG: Location enabled and no current location, starting updates")
            startLocationUpdates()
        } else {
            print("📍 DEBUG: Not starting location updates - enabled: \(isLocationEnabled), hasLocation: \(currentLocation != nil)")
        }
    }
    
    /// Starts location updates
    private func startLocationUpdates() {
        print("📍 DEBUG: startLocationUpdates called - isLocationEnabled: \(isLocationEnabled)")
        guard isLocationEnabled else { 
            print("📍 DEBUG: Location not enabled, returning early")
            return 
        }
        print("📍 DEBUG: Starting location manager updates...")
        isLoadingLocation = true
        locationManager.startUpdatingLocation()
        print("📍 DEBUG: locationManager.startUpdatingLocation() called")
    }
    
    /// Stops location updates
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLoadingLocation = false
    }
    
    /// Calculates distance between user and facility
    func distance(to facility: Facility) -> CLLocationDistance? {
        guard let currentLocation = currentLocation else { return nil }
        
        let facilityLocation = CLLocation(
            latitude: facility.coordinate.latitude,
            longitude: facility.coordinate.longitude
        )
        
        return currentLocation.distance(from: facilityLocation)
    }
    
    /// Formats distance for display
    func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 1
        
        if distance < 1000 {
            return formatter.string(from: Measurement(value: distance, unit: UnitLength.meters))
        } else {
            let kilometers = distance / 1000
            return formatter.string(from: Measurement(value: kilometers, unit: UnitLength.kilometers))
        }
    }
    
    /// Starts geo-fencing for a facility to enable wait time logging
    func startGeoFencing(for facility: Facility) {
        guard let currentLocation = currentLocation else { return }
        
        let facilityLocation = CLLocation(
            latitude: facility.coordinate.latitude,
            longitude: facility.coordinate.longitude
        )
        
        let distance = currentLocation.distance(from: facilityLocation)
        
        if distance <= geoFenceRadius {
            // User is within radius, start timer
            startGeoFenceTimer(for: facility.id)
        } else {
            // User is outside radius, stop timer
            stopGeoFenceTimer(for: facility.id)
        }
    }
    
    /// Stops geo-fencing for a facility
    func stopGeoFencing(for facilityId: String) {
        stopGeoFenceTimer(for: facilityId)
    }
    
    private func startGeoFenceTimer(for facilityId: String) {
        // Cancel existing timer if any
        geoFenceTimers[facilityId]?.invalidate()
        
        // Start new timer
        let timer = Timer.scheduledTimer(withTimeInterval: geoFenceMinTime, repeats: false) { [weak self] _ in
            self?.isNearFacility[facilityId] = true
        }
        
        geoFenceTimers[facilityId] = timer
    }
    
    private func stopGeoFenceTimer(for facilityId: String) {
        geoFenceTimers[facilityId]?.invalidate()
        geoFenceTimers.removeValue(forKey: facilityId)
        isNearFacility[facilityId] = false
    }
    
    /// Checks if user can log wait time for a facility (within geo-fence for required time)
    func canLogWaitTime(for facilityId: String) -> Bool {
        return isNearFacility[facilityId] ?? false
    }
    
    /// Sorts facilities by distance from user location
    func sortFacilitiesByDistance(_ facilities: [Facility]) -> [Facility] {
        guard currentLocation != nil else { return facilities }
        
        return facilities.sorted { facility1, facility2 in
            let distance1 = distance(to: facility1) ?? Double.greatestFiniteMagnitude
            let distance2 = distance(to: facility2) ?? Double.greatestFiniteMagnitude
            return distance1 < distance2
        }
    }
    
    /// Sorts facilities by wait time (shortest first)
    func sortFacilitiesByWaitTime(_ facilities: [Facility], waitTimes: [String: WaitTime]) -> [Facility] {
        return facilities.sorted { facility1, facility2 in
            let wait1 = waitTimes[facility1.id]?.waitMinutes ?? Int.max
            let wait2 = waitTimes[facility2.id]?.waitMinutes ?? Int.max
            return wait1 < wait2
        }
    }
    
    /// Gets the initial map region - user location if available, otherwise St. Louis
    func getInitialMapRegion() -> MKCoordinateRegion {
        if let userLocation = currentLocation {
            return MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        } else {
            // Fallback to St. Louis area
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
                span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
            )
        }
    }
    
    /// Centers map on user location with appropriate zoom level
    func getUserLocationRegion(withZoom zoom: MKCoordinateSpan? = nil) -> MKCoordinateRegion? {
        guard let userLocation = currentLocation else { return nil }
        
        let span = zoom ?? MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        return MKCoordinateRegion(center: userLocation.coordinate, span: span)
    }
    
    // MARK: - Driving Time Calculation
    
    /// Calculates driving time to a facility using Apple Maps routing
    func calculateDrivingTime(to facility: Facility) {
        guard let userLocation = currentLocation else {
            print("🚗 DEBUG: No user location available for driving time calculation to \(facility.name)")
            return
        }
        
        print("🚗 DEBUG: User location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
        print("🚗 DEBUG: Facility \(facility.name) location: \(facility.coordinate.latitude), \(facility.coordinate.longitude)")
        
        // Check cache first
        if let cachedData = drivingTimeCache[facility.id] {
            let cacheAge = Date().timeIntervalSince(cachedData.timestamp)
            if cacheAge < drivingTimeCacheExpiry {
                print("🚗 DEBUG: Using cached driving time for \(facility.name): \(Int(cachedData.time/60))min")
                DispatchQueue.main.async {
                    self.drivingTimes[facility.id] = cachedData.time
                }
                return
            }
        }
        
        // Don't calculate if already loading
        guard !isDrivingTimeLoading.contains(facility.id) else {
            print("🚗 DEBUG: Already calculating driving time for \(facility.name)")
            return
        }
        
        isDrivingTimeLoading.insert(facility.id)
        
        print("🚗 DEBUG: Starting Apple Maps calculation for \(facility.name)...")
        
        // Create MKDirections request
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: facility.coordinate))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isDrivingTimeLoading.remove(facility.id)
                
                if let error = error {
                    print("❌ DEBUG: Failed to calculate driving time to \(facility.name): \(error.localizedDescription)")
                    // For debugging: set a fallback time based on distance
                    if let distance = self?.distance(to: facility) {
                        let estimatedTime = distance / 1000 * 60 // Rough estimate: 1km per minute
                        print("🚗 DEBUG: Setting fallback driving time for \(facility.name): \(Int(estimatedTime/60))min")
                        self?.drivingTimes[facility.id] = estimatedTime
                    }
                    return
                }
                
                guard let route = response?.routes.first else {
                    print("❌ DEBUG: No route found to \(facility.name)")
                    return
                }
                
                let travelTime = route.expectedTravelTime
                print("🚗 DEBUG: SUCCESS! Driving time to \(facility.name): \(Int(travelTime/60))min (\(String(format: "%.1f", route.distance/1000))km)")
                
                // Update published properties
                self?.drivingTimes[facility.id] = travelTime
                
                // Cache the result
                self?.drivingTimeCache[facility.id] = (time: travelTime, timestamp: Date())
                
                print("🚗 DEBUG: Updated drivingTimes dictionary. Current count: \(self?.drivingTimes.count ?? 0)")
                print("🚗 DEBUG: drivingTimes now contains: \(self?.drivingTimes.keys.joined(separator: ", ") ?? "none")")
                print("🚗 DEBUG: Driving time for \(facility.id): \(travelTime) seconds (\(Int(travelTime/60)) minutes)")
            }
        }
    }
    
    /// Gets cached driving time for a facility in minutes
    func drivingTime(to facility: Facility) -> Int? {
        guard let timeInSeconds = drivingTimes[facility.id] else { return nil }
        return Int(timeInSeconds / 60) // Convert to minutes
    }
    
    /// Formats driving time for display
    func formatDrivingTime(to facility: Facility) -> String? {
        print("🚗 DEBUG: formatDrivingTime called for \(facility.name)")
        print("🚗 DEBUG: drivingTimes dictionary has \(drivingTimes.count) entries: \(drivingTimes.keys.joined(separator: ", "))")
        
        guard let minutes = drivingTime(to: facility) else { 
            print("🚗 DEBUG: No driving time found for \(facility.name) (ID: \(facility.id))")
            return nil 
        }
        
        let formattedTime: String
        if minutes == 0 {
            formattedTime = "<1min"
        } else if minutes < 60 {
            formattedTime = "\(minutes)min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            formattedTime = remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        }
        
        print("🚗 DEBUG: Formatted driving time for \(facility.name): \(formattedTime)")
        return formattedTime
    }
    
    /// TEST FUNCTION: Manually trigger driving time calculation for debugging
    func testDrivingTimeCalculation() {
        print("🧪 DEBUG: Manual test of driving time calculation triggered")
        print("🧪 DEBUG: Current location: \(currentLocation?.description ?? "nil")")
        print("🧪 DEBUG: drivingTimes dictionary count: \(drivingTimes.count)")
        
        // Test with first facility if available
        let testFacilityId = "total-access-12604" // Total Access Urgent Care - Clayton
        let testCoordinate = CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994) // St. Louis center
        
        guard let userLocation = currentLocation else {
            print("🧪 DEBUG: No user location available for test")
            return
        }
        
        print("🧪 DEBUG: Testing driving time calculation to test facility")
        print("🧪 DEBUG: User location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
        print("🧪 DEBUG: Test facility location: \(testCoordinate.latitude), \(testCoordinate.longitude)")
        
        // Create MKDirections request
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: testCoordinate))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🧪 DEBUG: Test calculation failed: \(error.localizedDescription)")
                    return
                }
                
                guard let route = response?.routes.first else {
                    print("🧪 DEBUG: No route found in test calculation")
                    return
                }
                
                let travelTime = route.expectedTravelTime
                print("🧪 DEBUG: TEST SUCCESS! Driving time: \(Int(travelTime/60))min")
                
                // Update published properties
                self?.drivingTimes[testFacilityId] = travelTime
                print("🧪 DEBUG: Test result stored in drivingTimes dictionary")
            }
        }
    }
    
    /// Calculates driving times for multiple facilities (batched to avoid rate limiting)
    func calculateDrivingTimes(for facilities: [Facility]) {
        guard currentLocation != nil else {
            print("🚗 No user location for batch driving time calculation")
            return
        }
        
        print("🚗 Starting batch driving time calculation for \(facilities.count) facilities")
        
        // Process facilities in small batches to avoid overwhelming the routing service
        let batchSize = 5
        let batches = facilities.chunked(into: batchSize)
        
        for (index, batch) in batches.enumerated() {
            let delay = Double(index) * 2.0 // 2 second delay between batches
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                for facility in batch {
                    self.calculateDrivingTime(to: facility)
                }
            }
        }
    }
}

// MARK: - Array Extension for Batching
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("📍 DEBUG: Location update received - \(locations.count) locations")
        guard let location = locations.last else { 
            print("📍 DEBUG: No valid location in update")
            return 
        }
        
        print("📍 DEBUG: New location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        currentLocation = location
        locationError = nil
        isLoadingLocation = false
        
        // Mark that we have received the initial location
        if !hasInitialLocation {
            hasInitialLocation = true
            print("📍 DEBUG: First location received! This should trigger driving time calculations")
            
            // Test a single driving time calculation to verify the API works
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.testDrivingTimeCalculation()
            }
        }
        
        // Update geo-fencing status for all monitored facilities
        for _ in geoFenceTimers.keys {
            // This would need the facility object to check distance
            // We'll handle this in the ViewModel when facilities are available
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoadingLocation = false
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .permissionDenied
            case .locationUnknown:
                locationError = .locationUnavailable
            case .network:
                locationError = .networkError
            default:
                locationError = .unknown
            }
        } else {
            locationError = .unknown
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 DEBUG: Authorization status changed to: \(status.rawValue) (\(authorizationStatusString(status)))")
        authorizationStatus = status
        isLocationEnabled = status == .authorizedWhenInUse || status == .authorizedAlways
        
        print("📍 DEBUG: Location enabled: \(isLocationEnabled)")
        
        if isLocationEnabled {
            print("📍 DEBUG: Starting location updates due to authorization change")
            startLocationUpdates()
        } else {
            print("📍 DEBUG: Stopping location updates due to authorization change")
            stopLocationUpdates()
            currentLocation = nil
            hasInitialLocation = false
            
            // Set appropriate error for denied states
            if status == .denied || status == .restricted {
                locationError = .permissionDenied
                print("📍 DEBUG: Location permission denied or restricted")
            }
        }
    }
    
    private func authorizationStatusString(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "unknown"
        }
    }
}

/// Errors that can occur with location services
enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationUnavailable
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied. Please enable location access in Settings."
        case .locationUnavailable:
            return "Location temporarily unavailable"
        case .networkError:
            return "Network error while obtaining location"
        case .unknown:
            return "Unknown location error"
        }
    }
} 