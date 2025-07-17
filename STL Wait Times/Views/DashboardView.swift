import SwiftUI
import MapKit

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
        center: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994), // St. Louis
        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0) // Wide view like Flighty
    )
    
    @State private var sheetState: BottomSheetState = .peek
    
    // MARK: - 3D Map Properties
    @State private var mapMode: MapDisplayMode = .hybrid2D
    @State private var selectedFacilityId: String? = nil
    
    // MARK: - Data Converter
    private let dataConverter = MapboxDataConverter()
    
    var body: some View {
        ZStack {
            // Background Map - Enhanced 3D Mapbox View
            MapboxView3D(
                coordinateRegion: $region,
                annotations: mapbox3DAnnotations,
                mapMode: mapMode,
                onMapTap: { coordinate in
                    handleMapTap(at: coordinate)
                },
                onAnnotationTap: { annotation in
                    handleFacilitySelection(annotation)
                }
            )
            .ignoresSafeArea()
            .opacity(sheetState == .expanded ? DashboardConstants.mapOpacity : 1.0)
            .animation(.easeInOut(duration: 0.3), value: sheetState)
            
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
    
    // MARK: - 3D Map Interaction Handlers
    
    /// Handle map tap gestures for 3D map
    /// - Parameter coordinate: The tapped coordinate on the map
    private func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        // Handle map tap interactions
        // Could be used for adding new facilities, getting info about location, etc.
        print("Map tapped at: \(coordinate.latitude), \(coordinate.longitude)")
        
        // Clear any selected facility
        selectedFacilityId = nil
        
        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    /// Handle facility annotation selection
    /// - Parameter annotation: The selected 3D facility annotation
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
    
    // MARK: - Map Annotations
    private var mapAnnotations: [FacilityMapAnnotation] {
        [
            FacilityMapAnnotation(id: "1", coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994), color: DashboardConstants.waitTimeRed),
            FacilityMapAnnotation(id: "2", coordinate: CLLocationCoordinate2D(latitude: 38.6470, longitude: -90.2394), color: DashboardConstants.waitTimeOrange),
            FacilityMapAnnotation(id: "3", coordinate: CLLocationCoordinate2D(latitude: 38.6070, longitude: -90.1594), color: DashboardConstants.waitTimeGreen)
        ]
    }
    
    // MARK: - Mapbox Annotations
    private var mapboxAnnotations: [CustomMapAnnotation] {
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
    
    // MARK: - 3D Mapbox Annotations
    /// Convert facility data to enhanced 3D annotations with wait times and priorities
    private var mapbox3DAnnotations: [MedicalFacility3DAnnotation] {
        // Convert current facility data to proper Facility models for 3D conversion
        let facilities = facilityData.map { dashboardFacility -> Facility in
            Facility(
                id: dashboardFacility.id,
                name: dashboardFacility.name,
                address: "Address", // TODO: Add actual address data
                city: "St. Louis",
                state: "MO", 
                zipCode: "63110",
                phone: "555-0123",
                facilityType: dashboardFacility.type == "ER" ? .emergencyDepartment : .urgentCare,
                coordinate: CLLocationCoordinate2D(
                    latitude: 38.6270, // Use facility coordinate when available
                    longitude: -90.1994
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
                    nextAvailableSlot: 0 // Default value
                )
                return (facility.id, waitTime)
            }
        )
        
        return dataConverter.convertToMapbox3DAnnotations(
            facilities: facilities,
            waitTimes: waitTimes,
            userLocation: nil // TODO: Get from LocationService
        )
    }
    
    // MARK: - Medical Facility Data
    private var facilityData: [MedicalFacility] {
        [
            MedicalFacility(
                id: "1",
                name: "Barnes-Jewish Hospital",
                type: "ER",
                waitTime: "45",
                waitDetails: "MINUTES",
                distance: "2.3 mi",
                waitChange: "+5 min",
                status: "Open",
                isOpen: true
            ),
            MedicalFacility(
                id: "2",
                name: "Saint Louis University",
                type: "ER",
                waitTime: "32",
                waitDetails: "MINUTES",
                distance: "1.8 mi",
                waitChange: "-2 min",
                status: "Open",
                isOpen: true
            ),
            MedicalFacility(
                id: "3",
                name: "Mercy Hospital South",
                type: "ER",
                waitTime: "18",
                waitDetails: "MINUTES",
                distance: "3.1 mi",
                waitChange: "Same",
                status: "Open",
                isOpen: true
            ),
            MedicalFacility(
                id: "4",
                name: "Christian Hospital",
                type: "ER",
                waitTime: "25",
                waitDetails: "MINUTES",
                distance: "4.2 mi",
                waitChange: "+3 min",
                status: "Open",
                isOpen: true
            ),
            MedicalFacility(
                id: "5",
                name: "Missouri Baptist Medical Center",
                type: "ER",
                waitTime: "38",
                waitDetails: "MINUTES",
                distance: "5.8 mi",
                waitChange: "-1 min",
                status: "Open",
                isOpen: true
            ),
            // Additional facilities for testing scroll functionality
            MedicalFacility(
                id: "6",
                name: "SSM Health Cardinal Glennon",
                type: "ER",
                waitTime: "22",
                waitDetails: "MINUTES",
                distance: "3.5 mi",
                waitChange: "+1 min",
                status: "Open",
                isOpen: true
            ),
            MedicalFacility(
                id: "7",
                name: "St. Luke's Hospital",
                type: "ER",
                waitTime: "52",
                waitDetails: "MINUTES",
                distance: "6.1 mi",
                waitChange: "+8 min",
                status: "Busy",
                isOpen: true
            ),
            MedicalFacility(
                id: "8",
                name: "Total Access Urgent Care",
                type: "UC",
                waitTime: "12",
                waitDetails: "MINUTES",
                distance: "1.2 mi",
                waitChange: "-3 min",
                status: "Open",
                isOpen: true
            ),
            MedicalFacility(
                id: "9",
                name: "Progress West Hospital",
                type: "ER",
                waitTime: "35",
                waitDetails: "MINUTES",
                distance: "7.8 mi",
                waitChange: "Same",
                status: "Open",
                isOpen: true
            ),
            MedicalFacility(
                id: "10",
                name: "Mercy-GoHealth Urgent Care",
                type: "UC",
                waitTime: "8",
                waitDetails: "MINUTES",
                distance: "2.1 mi",
                waitChange: "-5 min",
                status: "Open",
                isOpen: true
            )
        ]
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