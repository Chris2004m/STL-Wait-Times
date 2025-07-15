import Foundation
import CoreLocation
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
    
    private let geoFenceRadius: CLLocationDistance = 75.0 // 75 meters as specified in PRD
    private let geoFenceMinTime: TimeInterval = 5 * 60 // 5 minutes
    private var geoFenceTimers: [String: Timer] = [:]
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0 // Update every 10 meters
        
        authorizationStatus = locationManager.authorizationStatus
        isLocationEnabled = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    /// Requests location permission from user
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = .permissionDenied
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            locationError = .unknown
        }
    }
    
    /// Starts location updates
    private func startLocationUpdates() {
        guard isLocationEnabled else { return }
        locationManager.startUpdatingLocation()
    }
    
    /// Stops location updates
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
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
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationError = nil
        
        // Update geo-fencing status for all monitored facilities
        for _ in geoFenceTimers.keys {
            // This would need the facility object to check distance
            // We'll handle this in the ViewModel when facilities are available
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
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
        authorizationStatus = status
        isLocationEnabled = status == .authorizedWhenInUse || status == .authorizedAlways
        
        if isLocationEnabled {
            startLocationUpdates()
        } else {
            stopLocationUpdates()
            currentLocation = nil
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