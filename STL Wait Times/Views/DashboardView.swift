import SwiftUI
import MapKit
import CoreLocation

// MARK: - Bottom Sheet States
enum BottomSheetState: CaseIterable {
    case peek        // Shows 1 full row + peek of next
    case medium      // Shows 2 full rows  
    case expanded    // Shows 3+ rows with search
    
    var displayName: String {
        switch self {
        case .peek: return "Peek"
        case .medium: return "Medium"
        case .expanded: return "Expanded"
        }
    }
}

// MARK: - Constants
private enum DashboardConstants {
    // Bottom sheet offset percentages (matches Flighty app proportions)
    static let peekOffset: CGFloat = 0.72      // Shows ~28% of screen
    static let mediumOffset: CGFloat = 0.43    // Shows exactly 57% of screen  
    static let expandedOffset: CGFloat = 0.06  // Shows ~94% of screen
    
    // UI spacing and sizing
    static let cornerRadius: CGFloat = 20
    static let handleWidth: CGFloat = 40
    static let handleHeight: CGFloat = 5
    static let cardSpacing: CGFloat = 16
    static let dragThreshold: CGFloat = 60
    
    // Animation values
    static let springResponse: CGFloat = 0.5
    static let springDamping: CGFloat = 0.8
    static let mapOpacity: CGFloat = 0.3
    
    // Wait Time Color Coding
    static let waitTimeGreen = Color.green      // 0-20 min
    static let waitTimeOrange = Color.orange    // 21-45 min
    static let waitTimeRed = Color.red          // 46+ min
    
    // Standard iOS Colors
    static let primaryBlue = Color.blue
    static let systemGray = Color(.systemGray2)
}

struct DashboardView: View {
    
    // MARK: - State Properties
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994), // St. Louis fallback
        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0) // Wide view like Flighty
    )
    
    @State private var sheetState: BottomSheetState = .peek
    @State private var locationError: LocationError? = nil
    // Pending flag to auto-center once first location fix arrives after user taps button
    @State private var pendingCenterOnLocation: Bool = false
    // Trigger ID to force map recenter even when coordinates haven't changed
    @State private var recenterTrigger: UUID? = nil
    
    // MARK: - 3D Map Properties
    @State private var mapMode: MapDisplayMode = .hybrid2D
    
    // MARK: - Lighting
    @State private var lightsEnabled: Bool = true
    @State private var selectedFacilityId: String? = nil
    
    // MARK: - Services
    @StateObject private var locationService = LocationService.shared
    @StateObject private var waitTimeService = WaitTimeService.shared
    private let dataConverter = MapboxDataConverter()
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
    
    var body: some View {
        ZStack {
            // Background Map - Enhanced Mapbox View
            MapboxView(
                coordinateRegion: $region,
                annotations: mapboxAnnotations,
                mapStyle: "standard",
                lightsEnabled: lightsEnabled,
                onMapTap: { coordinate in
                    handleMapTap(at: coordinate)
                },
                recenterTrigger: recenterTrigger
            )
            .ignoresSafeArea()
            .opacity(sheetState == .expanded ? DashboardConstants.mapOpacity : 1.0)
            .animation(.easeInOut(duration: 0.3), value: sheetState)
            
            // Location Centering Button
            locationButton
            
            // Lights Toggle Button
            lightsToggleButton
            
            // Simple Reliable Bottom Sheet
            SimpleBottomSheetView(
                state: $sheetState,
                configuration: SimpleSheetConfiguration(),
                onStateChange: { newState in
                    handleSheetStateChange(newState)
                }
            ) {
                sheetContent
            }
        }
        // Center automatically when a new location arrives and the user requested it
        .onReceive(locationService.$currentLocation.compactMap { $0 }) { _ in
            if pendingCenterOnLocation {
                if let region = locationService.getUserLocationRegion() {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        self.region = region
                    }
                    pendingCenterOnLocation = false
                }
            }
        }
    }
    
    // MARK: - Location Button
    
    @ViewBuilder
    private var lightsToggleButton: some View {
        VStack {
            HStack {
                Spacer()
                
                // Lights toggle button matching compass/location button style
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        lightsEnabled.toggle()
                    }
                }) {
                    Image(systemName: lightsEnabled ? "lightbulb.fill" : "lightbulb")
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundColor(lightsEnabled ? .yellow : iconColor)
                }
                .frame(width: compassButtonSize, height: compassButtonSize)
                .background(compassButtonBackground)
                .clipShape(Circle())
                .shadow(color: compassShadowColor, radius: compassShadowRadius, x: compassShadowOffset.width, y: compassShadowOffset.height)
                .accessibility(label: Text(lightsEnabled ? "Disable 3D lights" : "Enable 3D lights"))
                .accessibility(hint: Text("Toggles dynamic 3D lighting effects on the map"))
                .padding(.trailing, compassButtonTrailingOffset) // Align with compass horizontally
            }
            
            Spacer()
        }
        .padding(.top, compassButtonTopOffset + compassButtonSize + buttonSpacing + compassButtonSize + buttonSpacing) // Position below location button with proper spacing
    }
    
    private var locationButton: some View {
        VStack {
            HStack {
                Spacer()
                
                // Location centering button matching compass button style
                Button(action: {
                    centerOnUserLocation()
                }) {
                    Group {
                        if locationService.isLoadingLocation {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: iconColor))
                        } else {
                            Image(systemName: locationButtonIcon)
                                .font(.system(size: iconSize, weight: .medium))
                                .foregroundColor(iconColor)
                        }
                    }
                    .frame(width: compassButtonSize, height: compassButtonSize)
                    .background(compassButtonBackground)
                    .clipShape(Circle())
                    .shadow(color: compassShadowColor, radius: compassShadowRadius, x: compassShadowOffset.width, y: compassShadowOffset.height)
                }
                .disabled(locationService.isLoadingLocation || (!locationService.isLocationEnabled && !locationService.isLoadingLocation))
                .opacity(buttonOpacity)
                .accessibility(label: Text("Center on my location"))
                .accessibility(hint: Text("Centers the map on your current location"))
                .padding(.trailing, compassButtonTrailingOffset) // Align with compass horizontally
            }
            
            Spacer()
        }
        .padding(.top, compassButtonTopOffset + compassButtonSize + buttonSpacing) // Position below compass button
    }
    
    // MARK: - Computed Properties for Consistent Styling
    
    /// Compass button size - matches native Mapbox control
    private var compassButtonSize: CGFloat {
        36 // Exact native Mapbox compass button size
    }
    
    /// Icon size matching native compass button
    private var iconSize: CGFloat {
        16 // Match compass icon size exactly
    }
    
    /// Background matching native Mapbox compass button
    private var compassButtonBackground: some View {
        // Dynamic background: match Mapbox compass button colors
        colorScheme == .dark ? Color.black.opacity(0.9) : Color.white.opacity(0.85)
    }
    
    /// Icon color matching native compass button
    private var iconColor: Color {
        (colorScheme == .dark ? Color.white : Color.black) // Dark mode → white icon, Light mode → black icon for contrast
    }
    
    /// Shadow color matching native compass button
    private var compassShadowColor: Color {
        .black.opacity(0.2) // More prominent shadow like native
    }
    
    /// Shadow radius matching native compass button
    private var compassShadowRadius: CGFloat {
        3 // Native compass shadow radius
    }
    
    /// Shadow offset matching native compass button
    private var compassShadowOffset: CGSize {
        CGSize(width: 0, height: 1) // Native compass shadow offset
    }
    
    /// Trailing offset matching native compass button
    private var compassButtonTrailingOffset: CGFloat {
        8 // Align horizontally with native compass
    }
    
    /// Top offset for compass button positioning
    private var compassButtonTopOffset: CGFloat {
        16 // Distance from top of safe area
    }
    
    /// Spacing between compass and location buttons
    private var buttonSpacing: CGFloat {
        8 // Consistent spacing between buttons
    }
    
    /// Location button icon based on state
    private var locationButtonIcon: String {
        if locationService.hasInitialLocation {
            return "location.fill"
        } else if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
            return "location.slash"
        } else {
            return "location"
        }
    }
    
    /// Button opacity based on location service state
    private var buttonOpacity: Double {
        if locationService.isLoadingLocation {
            return 1.0 // Keep visible when loading
        } else if locationService.isLocationEnabled {
            return 1.0 // Fully visible when enabled
        } else {
            return 0.6 // Dimmed when disabled
        }
    }
    
    // MARK: - Sheet Content
    
    @ViewBuilder
    private var sheetContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Text("Nearby Facilities")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .rotationEffect(.degrees(sheetState == .expanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: sheetState)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        // Share action
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.primary)
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    // Profile avatar
                    Circle()
                        .fill(DashboardConstants.primaryBlue)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("P")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .semibold))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Search Bar (only show when expanded)
            if sheetState == .expanded {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    Text("Search to add facilities")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Enhanced Facility List with smooth scrolling
            EnhancedScrollingView(
                items: visibleFacilities,
                sheetState: $sheetState,
                configuration: ScrollConfiguration(
                    itemSpacing: 0,
                    bottomPadding: 20,
                    dividerLeadingPadding: 80,
                    showScrollIndicators: false,
                    animationResponse: DashboardConstants.springResponse,
                    animationDamping: DashboardConstants.springDamping,
                    enableViewRecycling: true,
                    visibleRangeBuffer: 3
                ),
                onScrollPositionChange: { position in
                    handleScrollPositionChange(position)
                }
            ) { facility, index, sheetState in
                FacilityCard(
                    facility: facility,
                    isFirstCard: index == 0,
                    sheetState: sheetState
                )
            }
            
            // Fill remaining space to ensure sheet extends to bottom
            Spacer(minLength: 0)
        }
        .onAppear {
            setupInitialMapRegion()
            fetchInitialWaitTimes()
        }
        .onReceive(locationService.$hasInitialLocation) { hasLocation in
            if hasLocation {
                updateMapToUserLocation()
            }
        }
        .onReceive(waitTimeService.$waitTimes) { _ in
            // Trigger UI update when wait times are received
            // The facilityData computed property will automatically use the new wait times
        }
    }
    
    // MARK: - Computed Properties
    private var visibleFacilities: [MedicalFacility] {
        switch sheetState {
        case .peek:
            return facilityData // Show all facilities (scrollable)
        case .medium:
            return facilityData // Show all facilities
        case .expanded:
            return facilityData // Show all facilities
        }
    }
    
    /// Handle sheet state changes
    private func handleSheetStateChange(_ newState: BottomSheetState) {
        // Additional logic when sheet state changes
        // This is handled by the SimpleBottomSheetView now
    }
    
    /// Handle scroll position changes for analytics and optimization
    private func handleScrollPositionChange(_ position: ScrollPosition) {
        // Update analytics or perform actions based on scroll position
        // This can be used for performance monitoring and user behavior tracking
        
        // Example: Log scroll performance metrics
        #if DEBUG
        print("📊 Scroll Position: offset=\(position.offset), visible=\(position.visibleRange)")
        #endif
    }
    
    // MARK: - Location Setup Methods
    
    /// Set up initial map region - use user location if available, otherwise fallback to St. Louis
    private func setupInitialMapRegion() {
        // Set the region based on current location availability
        region = locationService.getInitialMapRegion()
    }
    
    /// Fetch initial wait times for all facilities
    private func fetchInitialWaitTimes() {
        print("🚀 Fetching initial wait times for all facilities...")
        waitTimeService.fetchAllWaitTimes(facilities: Array(FacilityData.allFacilities))
    }
    
    /// Update map to center on user location with smooth animation
    private func updateMapToUserLocation() {
        guard let userLocationRegion = locationService.getUserLocationRegion() else { return }
        
        withAnimation(.easeInOut(duration: 1.5)) {
            region = userLocationRegion
        }
        
        // Announce for accessibility
        let announcement = "Map centered on your location"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    // MARK: - 3D Map Interaction Handlers
    
    /// Handle map tap gestures for 3D map
    /// - Parameter coordinate: The tapped coordinate on the map
    private func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        // Handle map tap interactions
        print("Map tapped at: \(coordinate.latitude), \(coordinate.longitude)")
        
        // Reset sheet to peek state when tapping map
        withAnimation(.spring(response: DashboardConstants.springResponse, dampingFraction: DashboardConstants.springDamping)) {
            sheetState = .peek
        }
        
        // Clear any selected facility
        selectedFacilityId = nil
        
        
        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    /// Center the map on the user's current location
    private func centerOnUserLocation() {
        // Handle different location service states
        switch locationService.authorizationStatus {
        case .notDetermined:
            // Request permission if not yet determined
            locationService.requestLocationPermission()
            return
            
        case .denied, .restricted:
            // Show alert or handle denied permission
            locationError = LocationError.permissionDenied
            showLocationSettingsAlert()
            return
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission granted, proceed with centering
            break
            
        @unknown default:
            return
        }
        
        guard let userLocationRegion = locationService.getUserLocationRegion() else {
            // No location available yet, but permission is granted
            // Set flag so that we center once location arrives
            pendingCenterOnLocation = true
            return
        }
        
        // Animate the region change and trigger recenter
        withAnimation(.easeInOut(duration: 0.8)) {
            region = userLocationRegion
            // Generate new trigger ID to force MapboxView update
            recenterTrigger = UUID()
        }
        
        // Reset the recenter trigger after animation completes to prevent unwanted recentering
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // 1.5s animation + 0.5s buffer
            recenterTrigger = nil
        }
        
        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Announce for accessibility
        let announcement = "Map centered on your location"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    /// Show alert directing user to settings for location permission
    private func showLocationSettingsAlert() {
        // In a real app, you would present an alert here
        // For now, we'll just provide haptic feedback to indicate the action failed
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.error)
        
        // Announce for accessibility
        let announcement = "Location access denied. Please enable location access in Settings to use this feature."
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    /// Find nearby facility annotation for tap-to-fly functionality
    private func findNearbyFacility(coordinate: CLLocationCoordinate2D) -> CustomMapAnnotation? {
        let tapLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let threshold: CLLocationDistance = 1000 // 1km threshold
        
        return mapboxAnnotations.first { annotation in
            let facilityLocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            return tapLocation.distance(from: facilityLocation) < threshold
        }
    }
    
    /// Handle facility annotation selection
    /// - Parameter annotation: The selected 3D facility annotation
    // Note: Temporarily commented out since MapboxView doesn't support this callback yet
    /*
    private func handleFacilitySelection(_ annotation: MedicalFacility3DAnnotation) {
        // Update selected facility
        selectedFacilityId = annotation.id
        
        // Animate to show facility details in bottom sheet
        withAnimation(.spring(response: DashboardConstants.springResponse, dampingFraction: DashboardConstants.springDamping)) {
            if sheetState == .peek {
                sheetState = .medium
            }
        }
        
        // Announce selection for accessibility
        let announcement = "Selected \(annotation.name)"
        UIAccessibility.post(notification: .announcement, argument: announcement)
        
        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // TODO: Could trigger additional actions like:
        // - Updating region to center on facility
        // - Loading detailed facility information
        // - Starting navigation
    }
    */
    
    // MARK: - Map Annotations
    private var mapAnnotations: [FacilityMapAnnotation] {
        [
            FacilityMapAnnotation(id: "1", coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994), color: DashboardConstants.waitTimeRed),
            FacilityMapAnnotation(id: "2", coordinate: CLLocationCoordinate2D(latitude: 38.6470, longitude: -90.2394), color: DashboardConstants.waitTimeOrange),
            FacilityMapAnnotation(id: "3", coordinate: CLLocationCoordinate2D(latitude: 38.6070, longitude: -90.1594), color: DashboardConstants.waitTimeGreen)
        ]
    }
    
    // MARK: - Mapbox Annotations (Legacy)
    // Note: This is replaced by the more complete mapboxAnnotations method below
    /*
    private var mapboxAnnotationsLegacy: [CustomMapAnnotation] {
        mapAnnotations.map { annotation in
            CustomMapAnnotation(
                id: annotation.id,
                coordinate: annotation.coordinate,
                color: UIColor(annotation.color),
                title: nil,
                subtitle: nil
            )
        }
    }
    */
    
    // MARK: - 3D Mapbox Annotations
    /// Convert facility data to custom map annotations with wait times and priorities
    private var mapboxAnnotations: [CustomMapAnnotation] {
        // Convert current facility data to proper Facility models for 3D conversion
        let facilities = facilityData.enumerated().map { index, dashboardFacility -> Facility in
            // Use different coordinates for each facility to spread them around St. Louis
            let baseLatitude = 38.6270
            let baseLongitude = -90.1994
            let latOffset = (Double(index) - 2.0) * 0.02 // Spread facilities around
            let lonOffset = (Double(index % 3) - 1.0) * 0.03
            
            return Facility(
                id: dashboardFacility.id,
                name: dashboardFacility.name,
                address: "Address", // TODO: Add actual address data
                city: "St. Louis",
                state: "MO", 
                zipCode: "63110",
                phone: "555-0123",
                facilityType: dashboardFacility.type == "ER" ? .emergencyDepartment : .urgentCare,
                coordinate: CLLocationCoordinate2D(
                    latitude: baseLatitude + latOffset,
                    longitude: baseLongitude + lonOffset
                )
            )
        }
        
        // Create wait times dictionary
        let waitTimes: [String: WaitTime] = Dictionary(uniqueKeysWithValues: 
            facilityData.compactMap { facility -> (String, WaitTime)? in
                guard let waitMinutes = Int(facility.waitTime) else { return nil }
                let waitTime = WaitTime(
                    facilityId: facility.id,
                    waitMinutes: waitMinutes,
                    patientsInLine: 0, // Default value
                    lastUpdated: Date(),
                    nextAvailableSlot: 0, // Default value
                    status: .open // Default to open status
                )
                return (facility.id, waitTime)
            }
        )
        
        return dataConverter.convertToMapboxAnnotations(
            facilities: facilities,
            waitTimes: waitTimes,
            userLocation: locationService.currentLocation
        )
    }
    
    
    
    // MARK: - Medical Facility Data
    private var facilityData: [MedicalFacility] {
        // Convert real facilities to MedicalFacility format with real wait times
        let realFacilities = FacilityData.allFacilities.prefix(15).map { facility in
            MedicalFacility(
                id: facility.id,
                name: facility.name,
                type: facility.facilityType == .emergencyDepartment ? "ER" : "UC",
                waitTime: getRealWaitTime(for: facility),
                waitDetails: "MINUTES",
                distance: calculateDistance(to: facility),
                waitChange: generateMockWaitChange(), // Keep hardcoded as requested
                status: facility.statusString,
                isOpen: facility.isCurrentlyOpen
            )
        }
        
        return Array(realFacilities)
    }
    
    // MARK: - Helper Methods for Real Data Integration
    
    /// Get real wait time from WaitTimeService or fallback to reasonable defaults
    private func getRealWaitTime(for facility: Facility) -> String {
        // First check if facility is currently closed
        if !facility.isCurrentlyOpen {
            return "0" // Show 0 wait time for closed facilities
        }
        
        // Try to get real wait time from WaitTimeService
        if let waitTime = waitTimeService.getBestWaitTime(for: facility) {
            return "\(waitTime.waitMinutes)"
        }
        
        // Fallback to CMS data for emergency departments (only if open)
        if facility.facilityType == .emergencyDepartment,
           let cmsAverage = facility.cmsAverageWaitMinutes {
            return "\(cmsAverage)"
        }
        
        // Final fallback - generate reasonable defaults based on facility type and time (only if open)
        let hour = Calendar.current.component(.hour, from: Date())
        let baseWaitTime: Int
        
        switch facility.facilityType {
        case .emergencyDepartment:
            // Emergency departments are always open, so generate appropriate wait times
            switch hour {
            case 15...20: baseWaitTime = 55 // Busy evening hours
            case 8...14: baseWaitTime = 35  // Moderate daytime
            default: baseWaitTime = 25      // Quieter hours
            }
        case .urgentCare:
            // For urgent care, if we get here and facility is open, generate appropriate wait times
            switch hour {
            case 16...19: baseWaitTime = 20 // After work rush
            case 10...15: baseWaitTime = 15 // Moderate day
            default: baseWaitTime = 10      // Quieter hours
            }
        }
        
        // Add small random variation (±3 minutes)
        let variation = Int.random(in: -3...3)
        return "\(max(0, baseWaitTime + variation))"
    }
    
    /// Calculate distance to facility
    private func calculateDistance(to facility: Facility) -> String {
        if let distance = locationService.distance(to: facility) {
            return locationService.formatDistance(distance)
        } else {
            // Fallback calculation from St. Louis center
            let stlCenter = CLLocation(latitude: 38.6270, longitude: -90.1994)
            let facilityLocation = CLLocation(
                latitude: facility.coordinate.latitude,
                longitude: facility.coordinate.longitude
            )
            let distance = stlCenter.distance(from: facilityLocation)
            return locationService.formatDistance(distance)
        }
    }
    
    /// Generate mock wait time change until real implementation
    private func generateMockWaitChange() -> String {
        let changes = ["+2 min", "+5 min", "-3 min", "-1 min", "Same", "+1 min", "-2 min"]
        return changes.randomElement() ?? "Same"
    }
}

// MARK: - Models
struct FacilityMapAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let color: Color
}

struct MedicalFacility: Identifiable {
    let id: String
    let name: String
    let type: String
    let waitTime: String
    let waitDetails: String
    let distance: String
    let waitChange: String
    let status: String
    let isOpen: Bool
}

// MARK: - Facility Card
struct FacilityCard: View {
    let facility: MedicalFacility
    let isFirstCard: Bool
    let sheetState: BottomSheetState
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left: Wait time with centered alignment
            VStack(alignment: .center, spacing: 4) {
                Text(facility.waitTime)
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .foregroundColor(waitTimeColor)
                
                Text(facility.waitDetails)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.4)
            }
            .frame(width: 80, alignment: .center)
            
            // Center: Facility info
            VStack(alignment: .leading, spacing: 6) {
                Text(facility.type)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.4)
                
                Text(facility.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Facility details (show in all states)
                HStack(spacing: 18) {
                    // Distance
                    HStack(spacing: 4) {
                        Circle()
                            .fill(DashboardConstants.primaryBlue)
                            .frame(width: 8, height: 8)
                        
                        Text(facility.distance)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(DashboardConstants.primaryBlue)
                    }
                    
                    // Wait change
                    HStack(spacing: 4) {
                        Circle()
                            .fill(waitChangeColor)
                            .frame(width: 8, height: 8)
                        
                        Text(facility.waitChange)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(waitChangeColor)
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            // Right: Status
            VStack(alignment: .trailing, spacing: 4) {
                Text("Status")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.2)
                
                Text(facility.status)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(facility.isOpen ? .green : .red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, cardPadding)
        .opacity(cardOpacity)
        .frame(height: cardHeight)
        .clipped()
        .animation(.easeInOut(duration: 0.25), value: sheetState)
    }
    
    // MARK: - Color Logic
    private var waitTimeColor: Color {
        let waitMinutes = Int(facility.waitTime) ?? 0
        if waitMinutes <= 20 {
            return DashboardConstants.waitTimeGreen
        } else if waitMinutes <= 40 {
            return DashboardConstants.waitTimeOrange
        } else {
            return DashboardConstants.waitTimeRed
        }
    }
    
    private var waitChangeColor: Color {
        if facility.waitChange.contains("+") {
            return DashboardConstants.waitTimeRed
        } else if facility.waitChange.contains("-") {
            return DashboardConstants.waitTimeGreen
        } else {
            return DashboardConstants.systemGray
        }
    }
    
    // MARK: - Card Display Logic
    private var cardPadding: CGFloat {
        switch sheetState {
        case .peek:
            return DashboardConstants.cardSpacing  // Consistent spacing for all cards
        case .medium, .expanded:
            return DashboardConstants.cardSpacing
        }
    }
    
    private var cardOpacity: Double {
        switch sheetState {
        case .peek:
            return 1  // All cards fully visible for scrolling
        case .medium, .expanded:
            return 1
        }
    }
    
    private var cardHeight: CGFloat? {
        switch sheetState {
        case .peek:
            return nil  // Full height for all cards to enable proper scrolling
        case .medium, .expanded:
            return nil
        }
    }
}

// MARK: - Corner Radius Extension (Removed - now in SimpleBottomSheetView)

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}