import SwiftUI
import MapKit

struct FlightyDashboardView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
        span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
    )
    
    @State private var sheetState: SheetState = .peek
    
    enum SheetState: CaseIterable {
        case peek     // Tiny peek like Flighty initial
        case medium   // Medium view like Flighty middle  
        case expanded // Full expanded like Flighty final
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Map
                MapboxView(
                    coordinateRegion: $region,
                    annotations: mapboxAnnotations,
                    mapStyle: "standard"
                )
                .ignoresSafeArea()
                .opacity(sheetState == .expanded ? 0.3 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: sheetState)
                
                // Bottom Sheet
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Handle
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(Color(.systemGray4))
                            .frame(width: 36, height: 5)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                        
                        // Header
                        HStack {
                            HStack(spacing: 4) {
                                Text("My Facilities")
                                    .font(.system(size: 24, weight: .bold))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button {} label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.primary)
                                        .font(.system(size: 16, weight: .medium))
                                }
                                
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text("C")
                                            .foregroundColor(.white)
                                            .font(.system(size: 14, weight: .semibold))
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        
                        // Search Bar (only when fully expanded)
                        if sheetState == .expanded {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                Text("Search to add facilities")
                                    .foregroundColor(.secondary)
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
                        
                        // Facility List
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(facilities.indices, id: \.self) { index in
                                    let facility = facilities[index]
                                    
                                    FlightyCard(
                                        facility: facility,
                                        isFirstCard: index == 0,
                                        sheetState: sheetState
                                    )
                                    
                                    if index < facilities.count - 1 && sheetState == .expanded {
                                        Divider()
                                            .padding(.leading, 80)
                                    }
                                }
                            }
                            .padding(.bottom, 50)
                        }
                        .clipped()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                    .offset(y: sheetOffset(geometry))
                    .gesture(
                        DragGesture()
                            .onChanged { _ in
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 50
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    if value.translation.height < -threshold {
                                        // Swipe up - move to next state
                                        switch sheetState {
                                        case .peek:
                                            sheetState = .medium
                                        case .medium:
                                            sheetState = .expanded
                                        case .expanded:
                                            break // Already at top
                                        }
                                    } else if value.translation.height > threshold {
                                        // Swipe down - move to previous state
                                        switch sheetState {
                                        case .expanded:
                                            sheetState = .medium
                                        case .medium:
                                            sheetState = .peek
                                        case .peek:
                                            break // Already at bottom
                                        }
                                    }
                                }
                                
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                            }
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: sheetState)
                }
            }
        }
    }
    
    private func sheetOffset(_ geometry: GeometryProxy) -> CGFloat {
        switch sheetState {
        case .peek:
            return geometry.size.height * 0.88    // Tiny peek - just bottom edge visible
        case .medium:
            return geometry.size.height * 0.45    // Medium - show 3 cards like Flighty
        case .expanded:
            return geometry.size.height * 0.05    // Full expanded - 95% visible
        }
    }
    
    private var annotations: [FlightyMapAnnotation] {
        [
            FlightyMapAnnotation(id: "1", coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994), color: .red),
            FlightyMapAnnotation(id: "2", coordinate: CLLocationCoordinate2D(latitude: 38.6470, longitude: -90.2394), color: .blue),
            FlightyMapAnnotation(id: "3", coordinate: CLLocationCoordinate2D(latitude: 38.6070, longitude: -90.1594), color: .green)
        ]
    }
    
    // MARK: - Mapbox Annotations
    private var mapboxAnnotations: [CustomMapAnnotation] {
        annotations.map { annotation in
            CustomMapAnnotation(
                id: annotation.id,
                coordinate: annotation.coordinate,
                color: UIColor(annotation.color),
                title: nil,
                subtitle: nil
            )
        }
    }
    
    private var facilities: [FlightyData] {
        [
            FlightyData(id: "1", code: "BJH ED", route: "Barnes-Jewish Hospital", time: "45", detail: "MINUTES", status: "+5"),
            FlightyData(id: "2", code: "SLU ED", route: "Saint Louis University", time: "32", detail: "MINUTES", status: "-2"),
            FlightyData(id: "3", code: "MERCY", route: "Mercy Hospital South", time: "18", detail: "MINUTES", status: "On Time")
        ]
    }
}

struct FlightyMapAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let color: Color
}

struct FlightyData: Identifiable {
    let id: String
    let code: String
    let route: String
    let time: String
    let detail: String
    let status: String
}

struct FlightyCard: View {
    let facility: FlightyData
    let isFirstCard: Bool
    let sheetState: FlightyDashboardView.SheetState
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Large time on left
            VStack(alignment: .leading, spacing: 2) {
                Text(facility.time)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(facility.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            .frame(width: 80, alignment: .leading)
            
            // Center info
            VStack(alignment: .leading, spacing: 4) {
                Text(facility.code)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(facility.route)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Distance and details (only when fully expanded) - Flighty style
                if sheetState == .expanded {
                    HStack(spacing: 20) {
                        // Distance indicator
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 10, height: 10)
                            Text("2.3mi")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        // Update time indicator  
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.green)
                                .frame(width: 10, height: 10)
                            Text("5m ago")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            
            Spacer()
            
            // Status on right
            VStack(alignment: .trailing, spacing: 4) {
                Text("Change")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(facility.status)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(facility.status.hasPrefix("+") ? .red : facility.status.hasPrefix("-") ? .green : .primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, cardPadding)
        .opacity(cardOpacity)
        .frame(height: cardHeight)
        .clipped()
    }
    
    private var cardPadding: CGFloat {
        switch sheetState {
        case .peek:
            return isFirstCard ? 16 : 0
        case .medium, .expanded:
            return 16
        }
    }
    
    private var cardOpacity: Double {
        switch sheetState {
        case .peek:
            return isFirstCard ? 1 : 0
        case .medium:
            return 1
        case .expanded:
            return 1
        }
    }
    
    private var cardHeight: CGFloat? {
        switch sheetState {
        case .peek:
            return isFirstCard ? nil : 0
        case .medium, .expanded:
            return nil
        }
    }
}

// Corner radius extension is defined in DashboardView.swift

#Preview {
    FlightyDashboardView()
}