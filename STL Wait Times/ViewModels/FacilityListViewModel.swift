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
        let facilitiesWithAPIs = FacilityData.facilitiesWithAPIs
        if !facilitiesWithAPIs.isEmpty {
            waitTimeService.fetchAllWaitTimes(facilities: facilitiesWithAPIs)
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
            return "No data"
        }
        
        if waitTime.isStale {
            return "\(waitTime.displayText) (stale)"
        }
        
        return waitTime.displayText
    }
    
    func waitTimeSourceString(for facility: Facility) -> String {
        guard let waitTime = waitTime(for: facility) else {
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
    
    // MARK: - Cleanup
    deinit {
        refreshTimer?.invalidate()
    }
} 