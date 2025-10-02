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
    private var refreshTimer: DispatchSourceTimer?
    private var isAutoRefreshing = false
    private var lastAutoRefreshTime: Date?
    private let autoRefreshInterval: TimeInterval = 120.0 // 2 minutes
    
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
            .sink { [weak self] location in
                self?.sortFacilities()
                // Calculate driving times when location is available
                if location != nil {
                    // Location is now available for distance calculations
                }
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
                // Reset auto-refresh flag when loading completes
                if !isLoading {
                    self?.isAutoRefreshing = false
                }
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
        // Use DispatchSourceTimer for background-safe operation
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        timer.schedule(deadline: .now() + autoRefreshInterval, repeating: autoRefreshInterval)
        
        timer.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.performAutoRefresh()
            }
        }
        
        timer.resume()
        refreshTimer = timer
        
        print("✅ Background auto-refresh timer started (every \(Int(autoRefreshInterval))s)")
    }
    
    // MARK: - Data Loading
    func loadFacilities() {
        print("🚗 DEBUG: loadFacilities() starting")
        // Load all facilities from static data
        facilities = FacilityData.allFacilities
        print("🚗 DEBUG: Loaded \(facilities.count) facilities from FacilityData.allFacilities")
        
        // Request location permission
        locationService.requestLocationPermission()
        
        // Smart launch: Only fetch if we don't have recent data
        if shouldFetchOnAppLaunch() {
            print("🚀 App launch: Fetching fresh data (no recent cache)")
            refreshWaitTimes()
        } else {
            print("🚀 App launch: Using cached data, background refresh will update")
            // Still sort and filter with existing data
            sortFacilities()
        }
        
        // Apply initial filter
        applyFilter()
        
        // Trigger driving time calculations if location is already available
        // Facilities loaded - location-based sorting will happen automatically
    }
    
    /// Manual refresh triggered by user (pull-to-refresh, etc.)
    func refreshWaitTimes() {
        print("🔄 Manual refresh requested")
        
        // Don't trigger new API calls if auto-refresh is already running
        if isAutoRefreshing {
            print("🔄 Auto-refresh in progress, showing latest data")
            // Just refresh the UI with current data
            sortFacilities()
            return
        }
        
        performDataRefresh(isManual: true)
    }
    
    /// Background auto-refresh that runs every 2 minutes
    private func performAutoRefresh() {
        guard !isAutoRefreshing else {
            print("🔄 Auto-refresh already in progress, skipping")
            return
        }
        
        // Check if enough time has passed since last refresh
        if let lastRefresh = lastAutoRefreshTime {
            let timeSinceLastRefresh = Date().timeIntervalSince(lastRefresh)
            if timeSinceLastRefresh < autoRefreshInterval * 0.8 { // 80% of interval
                print("🔄 Auto-refresh skipped - too soon since last refresh (\(Int(timeSinceLastRefresh))s ago)")
                return
            }
        }
        
        print("🔄 Background auto-refresh triggered")
        performDataRefresh(isManual: false)
    }
    
    /// Determines if we should fetch data on app launch or use cached data
    private func shouldFetchOnAppLaunch() -> Bool {
        // If we have no cached data at all, definitely fetch
        if waitTimes.isEmpty {
            print("📊 App launch: No cached data available")
            return true
        }
        
        // Check if we have reasonably recent data for major facilities
        let totalAccessFacilities = FacilityData.allFacilities.filter { 
            $0.id.hasPrefix("total-access") || $0.apiEndpoint != nil 
        }
        
        let facilitiesWithData = totalAccessFacilities.filter { facility in
            waitTimes[facility.id] != nil
        }
        
        // If we have data for less than 80% of facilities, fetch fresh data
        let dataCompleteness = Double(facilitiesWithData.count) / Double(totalAccessFacilities.count)
        if dataCompleteness < 0.8 {
            print("📊 App launch: Incomplete data (\(facilitiesWithData.count)/\(totalAccessFacilities.count) facilities)")
            return true
        }
        
        // Check the age of our most recent data
        let mostRecentUpdate = waitTimes.values
            .map { $0.lastUpdated }
            .max() ?? Date.distantPast
        
        let dataAge = Date().timeIntervalSince(mostRecentUpdate)
        let maxAcceptableAge: TimeInterval = 300 // 5 minutes
        
        if dataAge > maxAcceptableAge {
            print("📊 App launch: Data too old (\(Int(dataAge))s ago, max \(Int(maxAcceptableAge))s)")
            return true
        }
        
        print("📊 App launch: Recent data available (\(Int(dataAge))s old, \(Int(dataCompleteness * 100))% complete)")
        return false
    }
    
    /// Core refresh logic used by both manual and auto-refresh
    private func performDataRefresh(isManual: Bool) {
        guard !isAutoRefreshing else {
            print("🔄 Refresh already in progress")
            return
        }
        
        isAutoRefreshing = true
        lastAutoRefreshTime = Date()
        
        print("🔄 DEBUG: performDataRefresh called (manual: \(isManual))")
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
            isAutoRefreshing = false
        }
    }
    
    // MARK: - Filtering and Sorting
    func applyFilter() {
        print("🔄 DEBUG: applyFilter() called - selectedFacilityType: \(selectedFacilityType.rawValue)")
        
        switch selectedFacilityType {
        case .emergencyDepartment:
            facilities = FacilityData.emergencyDepartments
            print("🔄 DEBUG: Loaded \(facilities.count) emergency departments")
        case .urgentCare:
            facilities = FacilityData.urgentCareCenters
            print("🔄 DEBUG: Loaded \(facilities.count) urgent care centers")
        }
        
        sortFacilities()
        
        // Facilities filtered and sorted by distance/wait time
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
        return converter.convertToMapAnnotations(
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
    
    /// Call this when the view appears to ensure driving times are calculated
    func onViewAppear() {
        print("🚗 DEBUG: onViewAppear() called")
        print("🚗 DEBUG: Current location in onViewAppear: \(locationService.currentLocation?.description ?? "nil")")
        print("🚗 DEBUG: Facilities count in onViewAppear: \(facilities.count)")
        print("🚗 DEBUG: Selected facility type in onViewAppear: \(selectedFacilityType.rawValue)")
        
        // View appeared - location-based functionality will work automatically
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
        refreshTimer?.cancel()
        refreshTimer = nil
    }
} 