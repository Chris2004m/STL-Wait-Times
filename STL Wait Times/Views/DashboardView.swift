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
private enum ThemePalette {
    static let midnightPrimary = Color(red: 0.25, green: 0.21, blue: 0.54)
    static let midnightSecondary = Color(red: 0.16, green: 0.13, blue: 0.38)
    static let midnightHighlight = Color(red: 0.44, green: 0.33, blue: 0.82)
    static let midnightAccent = Color(red: 0.58, green: 0.46, blue: 0.95)
    static let midnightGlow = Color.black.opacity(0.18)
    static let successStart = Color(red: 0.24, green: 0.78, blue: 0.69)
    static let successEnd = Color(red: 0.17, green: 0.62, blue: 0.55)
    static let dangerStart = Color(red: 0.83, green: 0.29, blue: 0.34)
    static let dangerEnd = Color(red: 0.68, green: 0.19, blue: 0.27)
    static let disabledStart = Color(red: 0.55, green: 0.57, blue: 0.64)
    static let disabledEnd = Color(red: 0.47, green: 0.49, blue: 0.56)
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
    
    // MARK: - Display Toggle State
    @State private var showPatientsInLine: Bool = false // true = patients, false = wait time (default: show wait time)
    @State private var isGlobalRefreshing: Bool = false // Track global refresh state
    
    // MARK: - 3D Map Properties
    @State private var mapMode: MapDisplayMode = .hybrid2D
    @State private var selectedFacilityId: String? = nil
    
    // MARK: - Services
    @StateObject private var locationService = LocationService.shared
    @StateObject private var waitTimeService = WaitTimeService.shared
    private let dataConverter = MapboxDataConverter() // TODO: Rename to AppleMapsConverter
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - User Preferences
    @AppStorage("preferred_map_style") private var preferredMapStyle: String = "standard"
    
    
    var body: some View {
        print("📱 DashboardView: Creating view body")
        
        return ZStack {
            // Background Map - Apple Maps View
            AppleMapsView(
                coordinateRegion: $region,
                annotations: facilityAnnotations,
                mapStyle: convertToAppleMapStyle(preferredMapStyle),
                showsUserLocation: true,
                onMapTap: { coordinate in
                    handleMapTap(at: coordinate)
                },
                recenterTrigger: recenterTrigger,
                selectedFacilityId: selectedFacilityId
            )
            .ignoresSafeArea()
            .opacity(sheetState == .expanded ? DashboardConstants.mapOpacity : 1.0)
            .animation(.easeInOut(duration: 0.3), value: sheetState)
            
            // Location Centering Button
            locationButton
            
            // Map Style Toggle Button
            mapStyleToggleButton
            
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
        .onAppear {
            print("✅ DashboardView: DashboardView appeared")
        }
        .onDisappear {
            print("❌ DashboardView: DashboardView disappeared")
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
    private var mapStyleToggleButton: some View {
        VStack {
            HStack {
                Spacer()
                
                // Map style toggle button (Standard/Satellite/Hybrid)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        // Cycle through: standard -> satellite -> hybrid -> standard
                        switch preferredMapStyle.lowercased() {
                        case "standard":
                            preferredMapStyle = "satellite"
                        case "satellite":
                            preferredMapStyle = "hybrid"
                        default:
                            preferredMapStyle = "standard"
                        }
                    }
                    // Haptic feedback
                    let selectionFeedback = UISelectionFeedbackGenerator()
                    selectionFeedback.selectionChanged()
                }) {
                    Image(systemName: mapStyleIcon)
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundColor(iconColor)
                }
                .frame(width: compassButtonSize, height: compassButtonSize)
                .background(compassButtonBackground)
                .clipShape(Circle())
                .shadow(color: compassShadowColor, radius: compassShadowRadius, x: compassShadowOffset.width, y: compassShadowOffset.height)
                .accessibility(label: Text(mapStyleAccessibilityLabel))
                .accessibility(hint: Text("Cycles between Standard, Satellite, and Hybrid map styles"))
                .padding(.trailing, compassButtonTrailingOffset)
            }
            
            Spacer()
        }
        .padding(.top, compassButtonTopOffset + compassButtonSize + buttonSpacing) // Position below location button
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
                                .scaleEffect(0.8 as CGFloat)
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
    
    /// Compass button size - matches native map controls
    private var compassButtonSize: CGFloat {
        36 // Standard map control button size
    }
    
    /// Icon size matching native compass button
    private var iconSize: CGFloat {
        16 // Match compass icon size exactly
    }
    
    /// Background matching native map compass button
    private var compassButtonBackground: some View {
        // Dynamic background: match system map button colors
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
    
    /// Map style icon based on current style
    private var mapStyleIcon: String {
        switch preferredMapStyle.lowercased() {
        case "standard":
            return "map"
        case "satellite":
            return "globe.americas.fill"
        case "hybrid":
            return "map.fill"
        default:
            return "map"
        }
    }
    
    /// Accessibility label for map style button
    private var mapStyleAccessibilityLabel: String {
        switch preferredMapStyle.lowercased() {
        case "standard":
            return "Current: Standard map. Tap to switch to Satellite"
        case "satellite":
            return "Current: Satellite map. Tap to switch to Hybrid"
        case "hybrid":
            return "Current: Hybrid map. Tap to switch to Standard"
        default:
            return "Change map style"
        }
    }
    
    /// Convert string map style to AppleMapStyle enum
    private func convertToAppleMapStyle(_ style: String) -> AppleMapStyle {
        switch style.lowercased() {
        case "satellite":
            return .satellite
        case "hybrid":
            return .hybrid
        default:
            return .standard
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
                

                
                // Header Action Buttons - Responsive layout
                HStack(spacing: hasNAFacilities && hasClockwiseMDFacilities ? 8 : 12) {
                    // Global Refresh Button (only show if there are N/A facilities)
                    if hasNAFacilities {
                        Button(action: {
                            refreshNAFacilities()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .medium))
                                    .rotationEffect(.degrees(isGlobalRefreshing ? 360 : 0))
                                    .animation(isGlobalRefreshing ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: isGlobalRefreshing)
                                Text("Refresh")
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, hasClockwiseMDFacilities ? 14 : 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(globalRefreshGradient)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                                    )
                            )
                            .shadow(color: globalRefreshShadow, radius: 8, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                        .disabled(isGlobalRefreshing)
                        .accessibility(label: Text("Refresh facilities showing N/A"))
                        .accessibility(hint: Text("Only refreshes facilities that currently show N/A wait times"))
                    }
                    
                    // Display Toggle Button (only show if there are ClockwiseMD facilities)
                    if hasClockwiseMDFacilities {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showPatientsInLine.toggle()
                            }
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            // Selection feedback
                            let selectionFeedback = UISelectionFeedbackGenerator()
                            selectionFeedback.selectionChanged()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: showPatientsInLine ? "person.2.fill" : "clock.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(showPatientsInLine ? "Patients" : "Time")
                                    .font(.system(size: 12, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, hasNAFacilities ? 14 : 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(timeToggleGradient)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                    )
                            )
                            .shadow(color: timeToggleShadow, radius: 10, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .accessibility(label: Text(showPatientsInLine ? "Switch to wait time display" : "Switch to patients in line display"))
                        .accessibility(hint: Text("Toggles between showing patient count and wait time for Total Access facilities"))
                    }
                }
                .fixedSize(horizontal: false, vertical: true) // Prevent vertical expansion but allow horizontal flexibility
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            

            
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
                    sheetState: sheetState,
                    onTap: {
                        handleFacilityTap(facility)
                    }
                )
            }
            
            // Fill remaining space to ensure sheet extends to bottom
            Spacer(minLength: 0)
        }
        .onAppear {
            print("✅ DashboardView: Sheet content appeared - setting up initial data")
            setupInitialMapRegion()
            fetchInitialWaitTimes()
        }
        .onReceive(locationService.$hasInitialLocation) { hasLocation in
            if hasLocation {
                updateMapToUserLocation()
            }
        }
        .onReceive(locationService.$currentLocation) { location in
            if location != nil {
                // Location updated - map will automatically update
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
    
    /// Check if there are any ClockwiseMD facilities that support both patients and wait time
    private var hasClockwiseMDFacilities: Bool {
        return FacilityData.allFacilities.contains { facility in
            facility.id.hasPrefix("total-access") || facility.id.hasPrefix("afc-")
        }
    }
    
    /// Check if there are any facilities currently showing N/A
    private var hasNAFacilities: Bool {
        return facilityData.contains { facility in
            facility.waitTime == "N/A"
        }
    }
    
    /// Get facilities that are currently showing N/A
    private var naFacilities: [Facility] {
        let naFacilityIds = facilityData.compactMap { facility in
            facility.waitTime == "N/A" ? facility.id : nil
        }
        
        return FacilityData.allFacilities.filter { facility in
            naFacilityIds.contains(facility.id)
        }
    }
    
    private var timeToggleGradient: LinearGradient {
        if showPatientsInLine {
            return LinearGradient(colors: [
                ThemePalette.midnightHighlight,
                ThemePalette.midnightAccent
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [
                ThemePalette.midnightPrimary,
                ThemePalette.midnightSecondary
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var timeToggleShadow: Color {
        ThemePalette.midnightGlow
    }

    private var globalRefreshGradient: LinearGradient {
        if isGlobalRefreshing {
            return LinearGradient(colors: [
                Color(red: 0.99, green: 0.58, blue: 0.25),
                Color(red: 1.0, green: 0.72, blue: 0.37)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [
                ThemePalette.midnightHighlight,
                ThemePalette.midnightAccent
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var globalRefreshShadow: Color {
        isGlobalRefreshing ? Color.black.opacity(0.12) : ThemePalette.midnightGlow
    }

    /// Refresh only facilities that are currently showing N/A
    private func refreshNAFacilities() {
        let facilitiesToRefresh = naFacilities
        
        guard !facilitiesToRefresh.isEmpty else {
            print("🔄 No N/A facilities to refresh")
            return
        }
        
        print("🔄 Global refresh: Refreshing \(facilitiesToRefresh.count) N/A facilities")
        
        // Start refresh state
        isGlobalRefreshing = true
        
        // Haptic feedback for refresh start
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Fetch wait times for N/A facilities only
        waitTimeService.fetchAllWaitTimes(facilities: facilitiesToRefresh)
        
        // Set a timer to reset the refresh state after a reasonable delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.isGlobalRefreshing = false
            
            // Success haptic feedback
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
            print("✅ Global refresh completed for N/A facilities")
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
        print("🗺️ DashboardView: Setting up initial map region")
        // Set the region based on current location availability
        region = locationService.getInitialMapRegion()
        print("🗺️ DashboardView: Initial map region set to: \(region.center.latitude), \(region.center.longitude)")
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
            // Generate new trigger ID to force map update
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
        
        return facilityAnnotations.first { annotation in
            let facilityLocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            return tapLocation.distance(from: facilityLocation) < threshold
        }
    }
    
    /// Handle facility card tap to center map on facility location with building-level precision
    /// - Parameter facility: The tapped medical facility
    private func handleFacilityTap(_ facility: MedicalFacility) {
        print("🏥 Facility tapped: \(facility.name)")
        
        // Find the actual facility data with coordinates
        guard let realFacility = FacilityData.allFacilities.first(where: { $0.id == facility.id }) else {
            print("❌ Could not find facility coordinates for \(facility.name)")
            return
        }
        
        // Update selected facility for highlighting
        selectedFacilityId = facility.id
        
        // Use building-level zoom with very tight coordinate spans for precise location viewing
        // 0.001 delta ≈ 111 meters, 0.002 delta ≈ 222 meters - perfect for seeing individual buildings
        let span = MKCoordinateSpan(
            latitudeDelta: 0.002,  // Building-level precision (~222m view radius)
            longitudeDelta: 0.002  // Tight enough to see exact building location
        )
        
        let targetRegion = MKCoordinateRegion(
            center: realFacility.coordinate,
            span: span
        )
        
        print("🎯 Centering map on \(realFacility.name)")
        print("   📍 Address: \(realFacility.address), \(realFacility.city), \(realFacility.state) \(realFacility.zipCode)")
        print("   🗺️ Coordinates: \(realFacility.coordinate.latitude), \(realFacility.coordinate.longitude)")
        print("   🔍 Zoom Level: Building-level precision (0.002° span = ~222m radius)")
        
        // Special logging for O'Fallon, IL facility to verify correct coordinates
        if facility.id == "total-access-15884" {
            print("✅ TESTING: O'Fallon, IL facility detected!")
            print("   🏢 Expected Address: 1103 Central Park Dr, O'Fallon, IL 62269")
            print("   📍 Expected Coordinates: (38.5906, -89.9107)")
            print("   🎯 Actual Coordinates: (\(realFacility.coordinate.latitude), \(realFacility.coordinate.longitude))")
            
            // Verify coordinates match expected values
            let expectedLat = 38.5906
            let expectedLon = -89.9107
            let latMatch = abs(realFacility.coordinate.latitude - expectedLat) < 0.0001
            let lonMatch = abs(realFacility.coordinate.longitude - expectedLon) < 0.0001
            
            if latMatch && lonMatch {
                print("   ✅ COORDINATES VERIFIED: Exact match with expected building location!")
            } else {
                print("   ❌ COORDINATE MISMATCH: Check FacilityData for correct coordinates")
            }
        }
        
        // Animate to the facility location with smooth transition
        withAnimation(.easeInOut(duration: 1.5)) {
            region = targetRegion
        }
        
        // Trigger recenter to ensure map updates even if coordinates are the same
        recenterTrigger = UUID()
        
        // Reset the recenter trigger after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            recenterTrigger = nil
        }
        
        // Collapse bottom sheet to medium to show more of the map
        withAnimation(.spring(response: DashboardConstants.springResponse, dampingFraction: DashboardConstants.springDamping)) {
            if sheetState == .expanded {
                sheetState = .medium
            }
        }
        
        // Provide haptic feedback for successful tap
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Announce for accessibility
        let announcement = "Map centered on \(facility.name) with building-level precision"
        UIAccessibility.post(notification: .announcement, argument: announcement)
        
        print("✅ Building-level map centering animation started for \(facility.name)")
    }
    
    // MARK: - Map Annotations
    private var mapAnnotations: [FacilityMapAnnotation] {
        [
            FacilityMapAnnotation(id: "1", coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994), color: DashboardConstants.waitTimeRed),
            FacilityMapAnnotation(id: "2", coordinate: CLLocationCoordinate2D(latitude: 38.6470, longitude: -90.2394), color: DashboardConstants.waitTimeOrange),
            FacilityMapAnnotation(id: "3", coordinate: CLLocationCoordinate2D(latitude: 38.6070, longitude: -90.1594), color: DashboardConstants.waitTimeGreen)
        ]
    }
    
    // MARK: - Facility Annotations (Legacy)
    // Note: This is replaced by the more complete facilityAnnotations method below
    /*
    private var facilityAnnotationsLegacy: [CustomMapAnnotation] {
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
    
    // MARK: - Facility Annotations
    /// Convert facility data to custom map annotations with real coordinates and wait times
    private var facilityAnnotations: [CustomMapAnnotation] {
        // Use real facilities from FacilityData with authentic coordinates
        let realFacilities = facilityData.compactMap { dashboardFacility -> Facility? in
            // Find the corresponding real facility data with authentic coordinates
            guard let realFacility = FacilityData.allFacilities.first(where: { $0.id == dashboardFacility.id }) else {
                print("⚠️ Could not find real facility data for \(dashboardFacility.name)")
                return nil
            }
            return realFacility
        }
        
        // Create wait times dictionary from current dashboard data
        let waitTimes: [String: WaitTime] = Dictionary(uniqueKeysWithValues: 
            facilityData.compactMap { facility -> (String, WaitTime)? in
                let waitMinutes: Int
                if let minutes = Int(facility.waitTime) {
                    waitMinutes = minutes
                } else {
                    // Handle N/A or other non-numeric wait times
                    waitMinutes = 0
                }
                
                let waitTime = WaitTime(
                    facilityId: facility.id,
                    waitMinutes: waitMinutes,
                    patientsInLine: 0, // Default value - will be updated from real API data
                    lastUpdated: Date(),
                    nextAvailableSlot: waitMinutes, // Use wait time as next available slot fallback
                    status: facility.isOpen ? .open : .closed,
                    waitTimeRange: facility.waitTime == "N/A" ? nil : "\(waitMinutes)"
                )
                return (facility.id, waitTime)
            }
        )
        
        print("🗺️ Creating facility annotations for \(realFacilities.count) facilities with real coordinates")
        for facility in realFacilities.prefix(3) {
            print("   - \(facility.name): \(facility.coordinate.latitude), \(facility.coordinate.longitude)")
        }
        
        return dataConverter.convertToMapAnnotations(
            facilities: realFacilities,
            waitTimes: waitTimes,
            userLocation: locationService.currentLocation,
            selectedFacilityId: selectedFacilityId
        )
    }
    
    
    
    // MARK: - Medical Facility Data
    private var facilityData: [MedicalFacility] {
        // Sort facilities by distance from user location first, then convert to MedicalFacility format
        let sortedFacilities = locationService.sortFacilitiesByDistance(FacilityData.allFacilities)
        
        // Convert sorted facilities to MedicalFacility format with real wait times
        let realFacilities = sortedFacilities.map { facility in
            MedicalFacility(
                id: facility.id,
                name: getTAUCDisplayName(for: facility),
                type: facility.facilityType == .emergencyDepartment ? "ER" : (facility.id.hasPrefix("total-access") ? "TAUC" : (facility.id.hasPrefix("mercy-gohealth") ? "Mercy" : (facility.id.hasPrefix("afc-") ? "AFC" : "UC"))),
                waitTime: getRealWaitTime(for: facility),
                waitDetails: getWaitDetails(for: facility),
                distance: calculateDistance(to: facility),
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
            return "0" // Show 0 for closed facilities
        }
        
        // Try to get real wait time from WaitTimeService
        if let waitTime = waitTimeService.getBestWaitTime(for: facility) {
            // For ClockwiseMD facilities (Total Access + AFC), respect the toggle
            if facility.id.hasPrefix("total-access") || facility.id.hasPrefix("afc-") {
                if showPatientsInLine {
                    return "\(waitTime.patientsInLine)"
                } else {
                    // Use next_available_visit for most accurate real-time wait time
                    print("🔍 DEBUG Wait Time Display for \(facility.name):")
                    print("   - waitTime.waitMinutes: \(waitTime.waitMinutes) (averaged range)")
                    print("   - waitTime.nextAvailableSlot: \(waitTime.nextAvailableSlot) (actual next slot)")
                    print("   - waitTime.waitTimeRange: \(waitTime.waitTimeRange ?? "nil")")
                    
                    // Prioritize nextAvailableSlot for most accurate wait time
                    let displayWaitTime = waitTime.nextAvailableSlot
                    print("   → Displaying: \(displayWaitTime) minutes (from nextAvailableSlot)")
                    return "\(displayWaitTime)"
                }
            } else {
                // For other facilities (Mercy GoHealth), always show wait time
                return "\(waitTime.waitMinutes)"
            }
        }
        
        // Fallback to CMS data for emergency departments (only if open)
        if facility.facilityType == .emergencyDepartment,
           let cmsAverage = facility.cmsAverageWaitMinutes {
            return "\(cmsAverage)"
        }
        
        // No real data available - return N/A
        return "N/A"
    }
    
    /// Get the appropriate wait details label for the facility
    private func getWaitDetails(for facility: Facility) -> String {
        // For ClockwiseMD facilities (Total Access + AFC), respect the toggle
        if facility.id.hasPrefix("total-access") || facility.id.hasPrefix("afc-") {
            return showPatientsInLine ? "PATIENTS" : "MINUTES"
        } else {
            // For other facilities (Mercy GoHealth), always show "MINUTES"
            return "MINUTES"
        }
    }
    
    /// Get display name for TAUC facilities (extract location) or use full name for others
    private func getTAUCDisplayName(for facility: Facility) -> String {
        if facility.id.hasPrefix("total-access") {
            // Extract location from "Total Access Urgent Care - Location" format
            let fullName = facility.name
            if let dashIndex = fullName.range(of: " - ") {
                let locationName = String(fullName[dashIndex.upperBound...])
                return locationName
            }
            // Fallback to full name if format doesn't match
            return facility.name
        } else {
            // For non-TAUC facilities, use the full name
            return facility.name
        }
    }
    
    /// Calculate distance and driving time to facility in format "2.1 mi • 🚗 5min"
    private func calculateDistance(to facility: Facility) -> String {
        // Get distance (either real location or fallback)
        let distanceString: String
        if let distance = locationService.distance(to: facility) {
            distanceString = locationService.formatDistance(distance)
        } else {
            // Fallback calculation from St. Louis center
            let stlCenter = CLLocation(latitude: 38.6270, longitude: -90.1994)
            let facilityLocation = CLLocation(
                latitude: facility.coordinate.latitude,
                longitude: facility.coordinate.longitude
            )
            let distance = stlCenter.distance(from: facilityLocation)
            distanceString = locationService.formatDistance(distance)
        }
        
        // Return distance only (driving time feature removed)
        return distanceString
    }
    
    /// Parse wait time range (e.g., "12 - 27") and return the average
    private func averageWaitTimeFromRange(_ range: String) -> Int {
        // Handle common range formats: "12 - 27", "4-19", "15 to 30", etc.
        let cleanRange = range.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try different separators
        let separators = [" - ", "-", " to ", "to"]
        
        for separator in separators {
            let components = cleanRange.components(separatedBy: separator)
            if components.count == 2 {
                let trimmedComponents = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                
                // Extract numbers from each component
                if let minWait = extractNumber(from: trimmedComponents[0]),
                   let maxWait = extractNumber(from: trimmedComponents[1]) {
                    let average = (minWait + maxWait) / 2
                    print("📊 Parsed wait time range '\(range)' → \(minWait)-\(maxWait) → avg: \(average)")
                    return average
                }
            }
        }
        
        // If parsing fails, try to extract a single number
        if let singleNumber = extractNumber(from: cleanRange) {
            print("📊 Parsed single wait time '\(range)' → \(singleNumber)")
            return singleNumber
        }
        
        print("⚠️ Failed to parse wait time range: '\(range)' - returning -1 to indicate parsing failure")
        return -1 // Return -1 to indicate parsing failure
    }
    
    /// Extract the first number from a string
    private func extractNumber(from text: String) -> Int? {
        let pattern = #"\d+"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }
        
        return Int(String(text[range]))
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
    let status: String
    let isOpen: Bool
}

// MARK: - Facility Card
struct FacilityCard: View {
    let facility: MedicalFacility
    let isFirstCard: Bool
    let sheetState: BottomSheetState
    let onTap: () -> Void
    
    // Add navigation-related properties
    @StateObject private var simpleNavigationManager = SimpleNavigationManager.shared
    @StateObject private var waitTimeService = WaitTimeService.shared
    @State private var isNavigating = false
    @State private var showingNavigationAlert = false
    @State private var navigationError: NavigationError?
    
    // Track navigation state per facility
    @State private var navigationFacilityId: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
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
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.9)
                    
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
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
                
                // Right: Status and Navigation
                VStack(alignment: .trailing, spacing: 10) {
                    statusBadge
                        .padding(.top, 2)

                    Button(action: handleNavigationTap) {
                        HStack(spacing: 6) {
                            Image(systemName: navigationButtonIcon)
                                .font(.system(size: 11, weight: .semibold))
                            Text("Navigate")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(navigationForegroundColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minWidth: 96)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(navigationButtonGradient)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                )
                        )
                        .shadow(color: navigationButtonShadow, radius: 8, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canNavigate)
                    .accessibilityLabel("Navigate to \(facility.name)")
                    .accessibilityHint(canNavigate ? "Starts turn-by-turn navigation to this medical facility" : "Navigation not available. Check location permissions.")
                }
                .frame(maxHeight: .infinity, alignment: .topTrailing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, cardPadding)
            
            // Navigation progress indicator (shown when navigating this specific facility)
            if isNavigating && navigationFacilityId == facility.id {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text("Opening in Maps...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .opacity(cardOpacity)
        .frame(height: cardHeight)
        .clipped()
        .animation(.easeInOut(duration: 0.25), value: sheetState)
        .onTapGesture {
            onTap()
        }
        .accessibilityAction(named: "Center map on facility") {
            onTap()
        }
        .alert("Navigation Error", isPresented: $showingNavigationAlert) {
            Button("OK") { }
        } message: {
            Text(navigationError?.localizedDescription ?? "Unknown error occurred")
        }
        .onReceive(simpleNavigationManager.$isNavigating) { navigating in
            isNavigating = navigating
            
            // Clear navigation state when navigation stops
            if !navigating {
                navigationFacilityId = nil
            }
        }
    }
    
    // MARK: - Navigation Logic
    
    /// Handle navigation button tap
    private func handleNavigationTap() {
        guard canNavigate else { return }
        
        // Set the facility ID for this navigation
        navigationFacilityId = facility.id
        
        // Convert MedicalFacility to Facility model
        let facilityModel = convertToFacilityModel()
        
        // Start navigation using SimpleNavigationManager
        simpleNavigationManager.startNavigation(to: facilityModel) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    // Navigation started successfully - isNavigating will be set by the receiver
                    print("✅ Navigation started for facility: \(self.facility.name)")
                    
                    // Clear navigation state after a short delay since Maps opened
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.navigationFacilityId = nil
                    }
                    
                case .failure(let error):
                    // Handle navigation error
                    self.navigationError = error
                    self.showingNavigationAlert = true
                    self.navigationFacilityId = nil
                }
            }
        }
    }
    
    /// Convert MedicalFacility to Facility model for navigation
    private func convertToFacilityModel() -> Facility {
        // Look up the real facility from FacilityData using the facility ID
        guard let realFacility = FacilityData.allFacilities.first(where: { $0.id == facility.id }) else {
            print("⚠️ Navigation: Could not find facility \(facility.id) in FacilityData, using fallback")
            
            // Fallback: Create a facility with available data from MedicalFacility
            // This should only happen if there's a data inconsistency
            return Facility(
                id: facility.id,
                name: facility.name,
                address: "Unknown Address",
                city: "St. Louis",
                state: "MO",
                zipCode: "63110",
                phone: "555-0123",
                facilityType: facility.type == "ER" ? .emergencyDepartment : .urgentCare,
                coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994), // St. Louis fallback
                operatingHours: facility.type == "ER" ? OperatingHours.emergency24x7 : OperatingHours.standardUrgentCare
            )
        }
        
        print("✅ Navigation: Found real facility data for \(realFacility.name)")
        print("   📍 Address: \(realFacility.address), \(realFacility.city), \(realFacility.state) \(realFacility.zipCode)")
        print("   🗺️ Coordinates: \(realFacility.coordinate.latitude), \(realFacility.coordinate.longitude)")
        
        // Return the real facility with all authentic data
        return realFacility
    }
    
    
    /// Check if navigation is possible
    private var canNavigate: Bool {
        let facilityModel = convertToFacilityModel()
        return simpleNavigationManager.canNavigate(to: facilityModel)
    }
    
    /// Navigation button icon based on state
    private var navigationButtonIcon: String {
        if isNavigating && navigationFacilityId == facility.id {
            return "location.fill"
        } else {
            return "location"
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusIndicatorColor)
                .frame(width: 6, height: 6)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            Text(facility.status)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.96))
                .lineLimit(1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .frame(minWidth: 82, alignment: .center)
        .background(
            Capsule()
                .fill(statusBadgeGradient)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
        .shadow(color: ThemePalette.midnightGlow, radius: 6, x: 0, y: 3)
    }
    
    private var statusBadgeGradient: LinearGradient {
        if facility.isOpen {
            return LinearGradient(colors: [
                ThemePalette.successStart,
                ThemePalette.successEnd
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [
                ThemePalette.dangerStart,
                ThemePalette.dangerEnd
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var statusIndicatorColor: Color {
        facility.isOpen ? Color.white.opacity(0.85) : Color.white.opacity(0.9)
    }
    
    private var navigationButtonGradient: LinearGradient {
        if isNavigating && navigationFacilityId == facility.id {
            return LinearGradient(colors: [
                ThemePalette.successStart,
                ThemePalette.successEnd
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if !canNavigate {
            return LinearGradient(colors: [
                ThemePalette.disabledStart,
                ThemePalette.disabledEnd
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [
                ThemePalette.midnightHighlight,
                ThemePalette.midnightPrimary
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var navigationButtonShadow: Color {
        canNavigate ? ThemePalette.midnightGlow : Color.black.opacity(0.08)
    }
    
    private var navigationForegroundColor: Color {
        canNavigate ? Color.white : Color.white.opacity(0.78)
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

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
