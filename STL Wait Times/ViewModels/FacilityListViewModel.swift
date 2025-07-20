import Foundation
import Combine
import CoreLocation

/// Main ViewModel for the facility list view
class FacilityListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var facilities: [Facility] = []
    @Published var waitTimes: [String: WaitTime] = [:]
    @Published var selectedFacilityType: Facility.FacilityType = .urgentCare
    @Published var sortOption: SortOption = .distance
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showLocationPermissionAlert = false
    
    // MARK: - Private Properties
    private let waitTimeService = WaitTimeService.shared
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // MARK: - Enums
    enum SortOption: String, CaseIterable {
        case distance = "Distance"
        case waitTime = "Wait Time"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadFacilities()
        setupRefreshTimer()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind location service
        locationService.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.sortFacilities()
            }
            .store(in: &cancellables)
        
        locationService.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .denied || status == .restricted {
                    self?.showLocationPermissionAlert = true
                }
            }
            .store(in: &cancellables)
        
        // Bind wait time service
        waitTimeService.$waitTimes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] waitTimes in
                self?.waitTimes = waitTimes
                self?.sortFacilities()
            }
            .store(in: &cancellables)
        
        waitTimeService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
        
        waitTimeService.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error?.localizedDescription
            }
            .store(in: &cancellables)
    }
    
    private func setupRefreshTimer() {
        // Auto-refresh every 2 minutes as specified in PRD
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 120.0, repeats: true) { [weak self] _ in
            self?.refreshWaitTimes()
        }
    }
    
    // MARK: - Data Loading
    func loadFacilities() {
        // Load all facilities from static data
        facilities = FacilityData.allFacilities
        
        // Request location permission
        locationService.requestLocationPermission()
        
        // Load wait times
        refreshWaitTimes()
        
        // Apply initial filter
        applyFilter()
    }
    
    func refreshWaitTimes() {
        print("🔄 DEBUG: refreshWaitTimes called")
        print("🔄 DEBUG: FacilityData.allFacilities count: \(FacilityData.allFacilities.count)")
        
        // Include ALL Total Access facilities for refresh (both API and web scraping)
        let totalAccessFacilities = FacilityData.allFacilities.filter { 
            $0.id.hasPrefix("total-access") || $0.apiEndpoint != nil 
        }
        
        print("🔄 Refreshing \(totalAccessFacilities.count) facilities (including web scraping)")
        print("🔄 DEBUG: After filtering, facility IDs: \(totalAccessFacilities.map { $0.id })")
        
        for facility in totalAccessFacilities {
            print("   - \(facility.name): \(facility.apiEndpoint != nil ? "API+Web" : "Web Only")")
        }
        
        if !totalAccessFacilities.isEmpty {
            waitTimeService.fetchAllWaitTimes(facilities: totalAccessFacilities)
        } else {
            print("❌ No Total Access facilities found for refresh!")
        }
    }
    
    // MARK: - Filtering and Sorting
    func applyFilter() {
        switch selectedFacilityType {
        case .emergencyDepartment:
            facilities = FacilityData.emergencyDepartments
        case .urgentCare:
            facilities = FacilityData.urgentCareCenters
        }
        sortFacilities()
    }
    
    func sortFacilities() {
        switch sortOption {
        case .distance:
            facilities = locationService.sortFacilitiesByDistance(facilities)
        case .waitTime:
            facilities = locationService.sortFacilitiesByWaitTime(facilities, waitTimes: waitTimes)
        }
    }
    
    // MARK: - Helper Methods
    func waitTime(for facility: Facility) -> WaitTime? {
        return waitTimeService.getBestWaitTime(for: facility)
    }
    
    func distance(to facility: Facility) -> CLLocationDistance? {
        return locationService.distance(to: facility)
    }
    
    func formattedDistance(to facility: Facility) -> String? {
        guard let distance = distance(to: facility) else { return nil }
        return locationService.formatDistance(distance)
    }
    
    func waitTimeDisplayString(for facility: Facility) -> String {
        guard let waitTime = waitTime(for: facility) else {
            print("🔍 DEBUG: \(facility.name) has no wait time data available")
            return "No data"
        }
        
        // For Total Access urgent care facilities, show patients in line instead of wait time
        let isTotalAccess = facility.name.contains("Total Access") || facility.id.hasPrefix("total-access")
        
        print("🔍 DEBUG: \(facility.name)")
        print("   - isTotalAccess: \(isTotalAccess)")
        print("   - waitTime.status: \(waitTime.status)")
        print("   - waitTime.patientsInLine: \(waitTime.patientsInLine)")
        print("   - waitTime.displayText: \(waitTime.displayText)")
        print("   - waitTime.patientDisplayText: \(waitTime.patientDisplayText)")
        
        if waitTime.isStale {
            let displayText = isTotalAccess ? waitTime.patientDisplayText : waitTime.displayText
            print("   - FINAL (stale): \(displayText) (stale)")
            return "\(displayText) (stale)"
        }
        
        let finalText = isTotalAccess ? waitTime.patientDisplayText : waitTime.displayText
        print("   - FINAL: \(finalText)")
        return finalText
    }
    
    func waitTimeSourceString(for facility: Facility) -> String {
        guard waitTime(for: facility) != nil else {
            return ""
        }
        
        return "Live" // All wait times are now from the live API
    }
    
    func canLogWaitTime(for facility: Facility) -> Bool {
        return locationService.canLogWaitTime(for: facility.id)
    }
    
    // MARK: - Map Annotations
    func mapAnnotations() -> [CustomMapAnnotation] {
        let converter = MapboxDataConverter()
        return converter.convertToMapboxAnnotations(
            facilities: facilities,
            waitTimes: waitTimes,
            userLocation: locationService.currentLocation
        )
    }
    
    // MARK: - Actions
    func toggleFacilityType() {
        selectedFacilityType = selectedFacilityType == .emergencyDepartment ? .urgentCare : .emergencyDepartment
        applyFilter()
    }
    
    func setSortOption(_ option: SortOption) {
        sortOption = option
        sortFacilities()
    }
    
    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Manual Refresh
    
    /// Refreshes wait time for a single facility
    func refreshSingleFacility(_ facility: Facility) {
        print("🔄 Manual refresh requested for \(facility.name)")
        waitTimeService.fetchSingleFacilityWaitTime(facility: facility)
    }
    
    /// Checks if a facility is currently being refreshed
    func isRefreshing(_ facility: Facility) -> Bool {
        return waitTimeService.refreshingFacilities.contains(facility.id)
    }
    
    /// Checks if a facility should show the refresh option
    func shouldShowRefreshOption(for facility: Facility) -> Bool {
        // For testing purposes, show refresh button for all Total Access facilities
        // or facilities with no/stale data
        if facility.id.hasPrefix("total-access") {
            return true
        }
        
        guard let waitTime = waitTime(for: facility) else {
            // No wait time data - show refresh option
            return true
        }
        
        // Show refresh option if data is stale or shows "N/A"
        return waitTime.isStale || waitTime.displayText.contains("N/A") || waitTime.displayText.contains("No data")
    }
    
    // MARK: - Cleanup
    deinit {
        refreshTimer?.invalidate()
    }
} 