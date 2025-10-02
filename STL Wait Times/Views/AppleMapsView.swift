//
//  AppleMapsView.swift
//  STL Wait Times
//
//  Apple Maps integration with satellite imagery and realistic globe view
//  Created on 10/1/25
//

import SwiftUI
import MapKit
import CoreLocation

/// Configuration for Apple Maps view appearance and behavior
enum AppleMapStyle: String, CaseIterable {
    case standard = "Standard"
    case satellite = "Satellite"
    case hybrid = "Hybrid"
    
    var displayName: String { rawValue }
}

/// Apple Maps view with satellite imagery, realistic globe, and facility annotations
struct AppleMapsView: View {
    
    // MARK: - Properties
    
    /// Map camera position binding
    @Binding var coordinateRegion: MKCoordinateRegion
    
    /// Facility annotations to display
    var annotations: [CustomMapAnnotation]
    
    /// Current map style
    var mapStyle: AppleMapStyle
    
    /// Whether to show user location
    var showsUserLocation: Bool
    
    /// Callback for map tap events
    var onMapTap: ((CLLocationCoordinate2D) -> Void)?
    
    /// Trigger for recentering map
    var recenterTrigger: UUID?
    
    /// Selected facility ID for highlighting
    var selectedFacilityId: String?
    
    // MARK: - State
    
    @State private var mapCameraPosition: MapCameraPosition
    @State private var selectedAnnotationId: String?
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Initialization
    
    init(
        coordinateRegion: Binding<MKCoordinateRegion>,
        annotations: [CustomMapAnnotation] = [],
        mapStyle: AppleMapStyle = .satellite,
        showsUserLocation: Bool = true,
        onMapTap: ((CLLocationCoordinate2D) -> Void)? = nil,
        recenterTrigger: UUID? = nil,
        selectedFacilityId: String? = nil
    ) {
        self._coordinateRegion = coordinateRegion
        self.annotations = annotations
        self.mapStyle = mapStyle
        self.showsUserLocation = showsUserLocation
        self.onMapTap = onMapTap
        self.recenterTrigger = recenterTrigger
        self.selectedFacilityId = selectedFacilityId
        
        // Initialize camera position from region
        let center = coordinateRegion.wrappedValue.center
        let span = coordinateRegion.wrappedValue.span
        
        // Calculate approximate distance from span for camera
        let distance = Self.calculateDistance(from: span)
        
        self._mapCameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: center,
            span: span
        )))
    }
    
    // MARK: - Body
    
    var body: some View {
        Map(position: $mapCameraPosition, selection: $selectedAnnotationId) {
            // User location
            if showsUserLocation {
                UserAnnotation()
            }
            
            // Facility annotations
            ForEach(annotations) { annotation in
                Annotation(
                    annotation.title ?? "Facility",
                    coordinate: annotation.coordinate
                ) {
                    FacilityMarkerView(
                        annotation: annotation,
                        isSelected: annotation.id == selectedFacilityId
                    )
                }
                .tag(annotation.id)
            }
        }
        .mapStyle(currentMapStyle)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange { context in
            // Update coordinate region binding when camera changes
            DispatchQueue.main.async {
                coordinateRegion = context.region
            }
        }
        .onTapGesture(coordinateSpace: .local) { location in
            // Handle tap gesture - note: getting coordinate from tap is complex in SwiftUI Map
            // For now, we'll trigger the callback with current center
            if let callback = onMapTap {
                callback(coordinateRegion.center)
            }
        }
        .onChange(of: recenterTrigger) { oldValue, newValue in
            guard newValue != nil else { return }
            
            // Recenter map with animation
            withAnimation(.easeInOut(duration: 1.5)) {
                let distance = Self.calculateDistance(from: coordinateRegion.span)
                mapCameraPosition = .camera(MapCamera(
                    centerCoordinate: coordinateRegion.center,
                    distance: distance,
                    heading: 0,
                    pitch: mapStyle == .satellite ? 45 : 0
                ))
            }
        }
        .onChange(of: coordinateRegion) { oldValue, newValue in
            // Only update if change is significant to avoid loops
            let latDiff = abs(oldValue.center.latitude - newValue.center.latitude)
            let lonDiff = abs(oldValue.center.longitude - newValue.center.longitude)
            
            if latDiff > 0.001 || lonDiff > 0.001 {
                let distance = Self.calculateDistance(from: newValue.span)
                mapCameraPosition = .region(newValue)
            }
        }
        .onChange(of: selectedFacilityId) { _, newValue in
            selectedAnnotationId = newValue
        }
    }
    
    // MARK: - Map Style Configuration
    
    private var currentMapStyle: MapStyle {
        switch mapStyle {
        case .standard:
            return .standard(elevation: .realistic, pointsOfInterest: .including([.hospital, .publicTransport]))
        case .satellite:
            return .imagery(elevation: .realistic)
        case .hybrid:
            return .hybrid(elevation: .realistic, pointsOfInterest: .including([.hospital, .publicTransport]))
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate camera distance from coordinate span
    private static func calculateDistance(from span: MKCoordinateSpan) -> CLLocationDistance {
        // Approximate meters per degree of latitude
        let metersPerDegreeLat: Double = 111_000
        
        // Calculate distance based on latitude span
        let distance = span.latitudeDelta * metersPerDegreeLat * 1.5
        
        // Clamp between reasonable values
        return min(max(distance, 100), 20_000_000) // 100m to 20,000km
    }
}

// MARK: - Facility Marker View

/// Custom marker view for facility annotations
struct FacilityMarkerView: View {
    let annotation: CustomMapAnnotation
    let isSelected: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Outer glow for selected state
            if isSelected {
                Circle()
                    .fill(markerColor.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .blur(radius: 8)
            }
            
            // Main marker circle
            Circle()
                .fill(markerColor)
                .frame(width: isSelected ? 32 : 24, height: isSelected ? 32 : 24)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 2)
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // Icon
            Image(systemName: "cross.fill")
                .font(.system(size: isSelected ? 14 : 10, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
    
    private var markerColor: Color {
        Color(annotation.color)
    }
}

// MARK: - Preview

#Preview("Apple Maps - Satellite") {
    @Previewable @State var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    let sampleAnnotations = [
        CustomMapAnnotation(
            id: "1",
            coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
            color: .systemRed,
            title: "Barnes-Jewish Hospital",
            subtitle: "Emergency Department"
        ),
        CustomMapAnnotation(
            id: "2",
            coordinate: CLLocationCoordinate2D(latitude: 38.6470, longitude: -90.2394),
            color: .systemGreen,
            title: "Urgent Care Plus",
            subtitle: "15 min wait"
        ),
        CustomMapAnnotation(
            id: "3",
            coordinate: CLLocationCoordinate2D(latitude: 38.6070, longitude: -90.1594),
            color: .systemOrange,
            title: "St. Louis University Hospital",
            subtitle: "32 min wait"
        )
    ]
    
    return AppleMapsView(
        coordinateRegion: $region,
        annotations: sampleAnnotations,
        mapStyle: .satellite,
        showsUserLocation: true
    )
}

#Preview("Apple Maps - Standard") {
    @Previewable @State var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    return AppleMapsView(
        coordinateRegion: $region,
        annotations: [],
        mapStyle: .standard,
        showsUserLocation: true
    )
}

#Preview("Apple Maps - Hybrid") {
    @Previewable @State var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    return AppleMapsView(
        coordinateRegion: $region,
        annotations: [],
        mapStyle: .hybrid,
        showsUserLocation: true
    )
}
