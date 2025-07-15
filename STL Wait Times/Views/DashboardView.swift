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
    @State private var dragAmount = CGSize.zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Map - always fills top portion
                Map(coordinateRegion: $region)
                    .mapStyle(.standard(elevation: .flat))
                    .ignoresSafeArea()
                    .opacity(sheetState == .expanded ? DashboardConstants.mapOpacity : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: sheetState)
                
                // Bottom Sheet - always extends to bottom
                VStack(spacing: 0) {
                    // Handle bar - draggable area
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color(.systemGray4))
                        .frame(width: DashboardConstants.handleWidth, height: DashboardConstants.handleHeight)
                        .padding(.top, 10)
                        .padding(.bottom, 12)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragAmount = CGSize(width: 0, height: value.translation.height)
                                }
                                .onEnded { value in
                                    handleSheetDragEnd(value: value)
                                }
                        )
                    
                    // Header - draggable area
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
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragAmount = CGSize(width: 0, height: value.translation.height)
                            }
                            .onEnded { value in
                                handleSheetDragEnd(value: value)
                            }
                    )
                    
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
                    
                    // Facility List - fills remaining space to bottom
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(visibleFacilities.indices, id: \.self) { index in
                                let facility = visibleFacilities[index]
                                
                                FacilityCard(
                                    facility: facility,
                                    isFirstCard: index == 0,
                                    sheetState: sheetState
                                )
                                
                                if index < visibleFacilities.count - 1 {
                                    Divider()
                                        .padding(.leading, 80)
                                        .opacity(sheetState == .expanded ? 1.0 : 0.5)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .clipped()
                    
                    // Fill remaining space to ensure sheet extends to bottom
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Color(.systemBackground)
                        .opacity(0.98)
                )
                .cornerRadius(DashboardConstants.cornerRadius, corners: [.topLeft, .topRight])
                .shadow(color: .black.opacity(sheetState == .expanded ? DashboardConstants.mapOpacity : 0.1), radius: 10, x: 0, y: -5)
                .offset(y: sheetOffsetY(for: geometry))
                .offset(dragAmount)
                .animation(.spring(response: DashboardConstants.springResponse, dampingFraction: DashboardConstants.springDamping), value: sheetState)
            }
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
    
    private func sheetOffsetY(for geometry: GeometryProxy) -> CGFloat {
        switch sheetState {
        case .peek:
            return geometry.size.height * DashboardConstants.peekOffset
        case .medium:
            return geometry.size.height * DashboardConstants.mediumOffset
        case .expanded:
            return geometry.size.height * DashboardConstants.expandedOffset
        }
    }
    
    private func handleSheetDragEnd(value: DragGesture.Value) {
        let threshold: CGFloat = DashboardConstants.dragThreshold
        let previousState = sheetState
        
        withAnimation(.spring(response: DashboardConstants.springResponse, dampingFraction: DashboardConstants.springDamping)) {
            if value.translation.height < -threshold {
                // Drag up - move to next state
                switch sheetState {
                case .peek:
                    sheetState = .medium
                case .medium:
                    sheetState = .expanded
                case .expanded:
                    break // Already at max
                }
            } else if value.translation.height > threshold {
                // Drag down - move to previous state
                switch sheetState {
                case .expanded:
                    sheetState = .medium
                case .medium:
                    sheetState = .peek
                case .peek:
                    break // Already at min
                }
            }
            
            dragAmount = .zero
        }
        
        // Only provide haptic feedback if state actually changed
        if previousState != sheetState {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
    
    // MARK: - Map Annotations
    private var mapAnnotations: [FacilityMapAnnotation] {
        [
            FacilityMapAnnotation(id: "1", coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994), color: DashboardConstants.waitTimeRed),
            FacilityMapAnnotation(id: "2", coordinate: CLLocationCoordinate2D(latitude: 38.6470, longitude: -90.2394), color: DashboardConstants.waitTimeOrange),
            FacilityMapAnnotation(id: "3", coordinate: CLLocationCoordinate2D(latitude: 38.6070, longitude: -90.1594), color: DashboardConstants.waitTimeGreen)
        ]
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

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}