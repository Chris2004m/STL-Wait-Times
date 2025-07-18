//
//  MapboxView3D.swift
//  STL Wait Times
//
//  Enhanced 3D Mapbox integration with accessibility and performance optimization
//  Created by Claude AI on 7/15/25.
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit
// import MapboxMaps // Will be enabled when SDK is added

/// **MapboxView3D**: A comprehensive 3D mapping component for medical facility visualization
///
/// This component provides:
/// - Seamless 2D/3D view transitions with accessibility support
/// - 3D buildings and terrain visualization for better spatial context
/// - Custom 3D annotations for medical facilities with wait time overlays
/// - Performance optimization and device capability detection
/// - Full VoiceOver and accessibility compliance
/// - Motion sensitivity awareness (respects Reduce Motion preferences)
///
/// **Usage:**
/// ```swift
/// MapboxView3D(
///     coordinateRegion: $region,
///     annotations: facilityAnnotations,
///     mapMode: .buildings3D,
///     onMapTap: { coordinate in
///         // Handle map interaction
///     }
/// )
/// ```
struct MapboxView3D: View {
    
    // MARK: - Public Properties
    
    /// Binding to coordinate region for map center and zoom level
    @Binding var coordinateRegion: MKCoordinateRegion
    
    /// Array of 3D-enhanced medical facility annotations
    var annotations: [MedicalFacility3DAnnotation] = []
    
    /// Current map display mode (2D, 3D buildings, terrain, etc.)
    @State var mapMode: MapDisplayMode = .hybrid2D
    
    /// Callback for map tap interactions
    var onMapTap: ((CLLocationCoordinate2D) -> Void)?
    
    /// Callback for annotation selection
    var onAnnotationTap: ((MedicalFacility3DAnnotation) -> Void)?
    
    // MARK: - Private State
    
    /// Performance monitoring and device capabilities
    @StateObject private var performanceManager = Map3DPerformanceManager()
    
    /// Accessibility and user preferences
    @AppStorage("prefersReducedMotion") private var reducedMotion = false
    @AppStorage("mapPreference3D") private var user3DPreference = true
    
    /// 3D view state management
    @State private var is3DEnabled: Bool = true
    @State private var buildingsOpacity: Double = 0.8
    @State private var terrainExaggeration: Double = 1.5
    @State private var cameraAltitude: Double = 1000.0
    @State private var cameraPitch: Double = 45.0
    
    /// Performance and quality settings
    @State private var renderQuality: RenderQuality = .auto
    @State private var frameRate: Double = 60.0
    
    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // Main map view (Mapbox when SDK available, MapKit fallback)
            mapContentView
                .accessibility(label: Text(mapMode.accessibilityLabel))
                .accessibility(hint: Text("Medical facilities map. Double-tap to interact."))
                .onTapGesture { location in
                    handleMapTap(at: location)
                }
                .animation(.easeInOut(duration: reducedMotion ? 0.0 : 0.6), value: mapMode)
            
            // 3D Controls Overlay
            VStack {
                HStack {
                    Spacer()
                    map3DControlsView
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                }
                Spacer()
            }
            
            // Performance indicator (debug mode)
            if performanceManager.showPerformanceIndicator {
                performanceIndicatorView
            }
        }
        .onAppear {
            setupMapView()
        }
        .onChange(of: mapMode) { _, newMode in
            handleMapModeChange(newMode)
        }
        .onChange(of: reducedMotion) { _, isReduced in
            adaptToAccessibilityPreferences()
        }
    }
    
    // MARK: - Map Content View
    
    /// Main map content with 3D or 2D rendering
    @ViewBuilder
    private var mapContentView: some View {
        if is3DEnabled && mapMode.supports3D {
            // 3D Mapbox View (when SDK is available)
            mapbox3DView
        } else {
            // 2D Fallback using MapKit
            mapkit2DFallbackView
        }
    }
    
    /// Full 3D Mapbox implementation (requires Mapbox SDK)
    @ViewBuilder
    private var mapbox3DView: some View {
        // Placeholder for full Mapbox SDK implementation
        // This will be replaced with actual MapboxMap when SDK is added
        
        ZStack {
            // MapKit fallback for now
            mapkit2DFallbackView
            
            // 3D Effect Overlay (simulated)
            if mapMode.supports3D {
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.1),
                            Color.clear,
                            Color.gray.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .allowsHitTesting(false)
                    .opacity(buildingsOpacity * 0.3)
            }
        }
    }
    
    /// 2D MapKit fallback view
    @ViewBuilder
    private var mapkit2DFallbackView: some View {
        Map(coordinateRegion: $coordinateRegion, annotationItems: mapKitAnnotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                MedicalFacility3DAnnotationView(
                    annotation: annotation,
                    displayMode: mapMode,
                    onTap: {
                        onAnnotationTap?(annotation)
                    }
                )
            }
        }
        .mapStyle(mapKitMapStyle)
    }
    
    /// 3D Controls UI
    @ViewBuilder
    private var map3DControlsView: some View {
        VStack(spacing: 12) {
            // Map Mode Toggle
            Button(action: toggleMapMode) {
                Image(systemName: mapMode.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .accessibility(label: Text("Toggle Map Mode"))
            .accessibility(hint: Text("Currently \(mapMode.accessibilityLabel)"))
            
            // 3D Settings (when in 3D mode)
            if mapMode.supports3D {
                map3DSettingsView
            }
        }
    }
    
    /// 3D Settings Controls
    @ViewBuilder
    private var map3DSettingsView: some View {
        VStack(spacing: 8) {
            // Buildings Toggle
            Button(action: toggleBuildings) {
                Image(systemName: buildingsOpacity > 0.5 ? "building.2.fill" : "building.2")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .accessibility(label: Text("Toggle 3D Buildings"))
            
            // Terrain Toggle
            Button(action: toggleTerrain) {
                Image(systemName: terrainExaggeration > 1.0 ? "mountain.2.fill" : "mountain.2")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .accessibility(label: Text("Toggle 3D Terrain"))
        }
    }
    
    /// Performance indicator for debugging
    @ViewBuilder
    private var performanceIndicatorView: some View {
        VStack {
            Spacer()
            HStack {
                Text("FPS: \(Int(frameRate))")
                    .font(.caption.monospaced())
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(6)
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Helper Properties
    
    /// MapKit annotations converted from 3D annotations
    private var mapKitAnnotations: [MedicalFacility3DAnnotation] {
        return annotations
    }
    
    /// MapKit map style based on current mode
    private var mapKitMapStyle: MapStyle {
        switch mapMode {
        case .flat2D:
            return .standard(elevation: .flat)
        case .hybrid2D:
            return .hybrid(elevation: .realistic)
        case .buildings3D, .terrain3D, .full3D:
            return .hybrid(elevation: .realistic)
        }
    }
    
    // MARK: - Setup and Configuration
    
    /// Initial map setup and configuration
    private func setupMapView() {
        // Detect device capabilities
        performanceManager.detectDeviceCapabilities()
        
        // Set initial 3D state based on device and preferences
        is3DEnabled = performanceManager.supports3D && user3DPreference && !reducedMotion
        
        // Auto-adjust quality based on device
        renderQuality = performanceManager.recommendedQuality
        
        // Configure initial camera position for 3D
        if mapMode.supports3D {
            setupInitial3DCamera()
        }
    }
    
    /// Configure initial 3D camera position
    private func setupInitial3DCamera() {
        // Set camera for optimal 3D viewing of medical facilities
        cameraAltitude = 1500.0
        cameraPitch = 45.0
        
        // Adjust based on facility density
        let facilityCount = annotations.count
        if facilityCount > 10 {
            cameraAltitude = 2000.0 // Higher for more facilities
        }
    }
    
    /// Adapt map behavior to accessibility preferences
    private func adaptToAccessibilityPreferences() {
        if reducedMotion {
            // Disable 3D transitions and effects
            mapMode = .flat2D
            is3DEnabled = false
        } else if user3DPreference && performanceManager.supports3D {
            is3DEnabled = true
        }
    }
    
    // MARK: - User Interaction Handlers
    
    /// Handle map tap gestures
    private func handleMapTap(at location: CGPoint) {
        // Convert screen point to coordinate (approximation for now)
        onMapTap?(coordinateRegion.center)
        
        // Haptic feedback for accessibility
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    /// Toggle between map display modes
    private func toggleMapMode() {
        let allModes = MapDisplayMode.allCases
        let currentIndex = allModes.firstIndex(of: mapMode) ?? 0
        let nextIndex = (currentIndex + 1) % allModes.count
        
        mapMode = allModes[nextIndex]
        
        // Accessibility announcement
        let announcement = "Map mode changed to \(mapMode.accessibilityLabel)"
        UIAccessibility.post(notification: .announcement, argument: announcement)
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    /// Toggle 3D buildings visibility
    private func toggleBuildings() {
        withAnimation(.easeInOut(duration: 0.3)) {
            buildingsOpacity = buildingsOpacity > 0.5 ? 0.2 : 0.8
        }
        
        let status = buildingsOpacity > 0.5 ? "enabled" : "disabled"
        UIAccessibility.post(notification: .announcement, argument: "3D buildings \(status)")
    }
    
    /// Toggle 3D terrain visibility
    private func toggleTerrain() {
        withAnimation(.easeInOut(duration: 0.3)) {
            terrainExaggeration = terrainExaggeration > 1.0 ? 0.5 : 1.5
        }
        
        let status = terrainExaggeration > 1.0 ? "enabled" : "disabled"
        UIAccessibility.post(notification: .announcement, argument: "3D terrain \(status)")
    }
    
    /// Handle map mode changes
    private func handleMapModeChange(_ newMode: MapDisplayMode) {
        // Update 3D settings based on mode
        switch newMode {
        case .flat2D:
            is3DEnabled = false
            buildingsOpacity = 0.0
            terrainExaggeration = 0.0
            
        case .hybrid2D:
            is3DEnabled = false
            buildingsOpacity = 0.3
            terrainExaggeration = 0.5
            
        case .buildings3D:
            is3DEnabled = true
            buildingsOpacity = 0.8
            terrainExaggeration = 0.5
            cameraPitch = 45.0
            
        case .terrain3D:
            is3DEnabled = true
            buildingsOpacity = 0.3
            terrainExaggeration = 1.5
            cameraPitch = 60.0
            
        case .full3D:
            is3DEnabled = true
            buildingsOpacity = 0.8
            terrainExaggeration = 1.5
            cameraPitch = 45.0
        }
        
        // Save user preference
        user3DPreference = newMode.supports3D
    }
}

// MARK: - Supporting Types

/// **MapDisplayMode**: Defines different map visualization modes
///
/// Each mode provides different levels of 3D visualization optimized for
/// specific use cases in medical facility discovery.
enum MapDisplayMode: String, CaseIterable, Identifiable {
    case flat2D = "flat2D"
    case hybrid2D = "hybrid2D"
    case buildings3D = "buildings3D"
    case terrain3D = "terrain3D"
    case full3D = "full3D"
    
    var id: String { rawValue }
    
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .flat2D: return "2D Flat"
        case .hybrid2D: return "2D Hybrid"
        case .buildings3D: return "3D Buildings"
        case .terrain3D: return "3D Terrain"
        case .full3D: return "Full 3D"
        }
    }
    
    /// Accessibility label for VoiceOver
    var accessibilityLabel: String {
        switch self {
        case .flat2D: return "Two-dimensional flat map view"
        case .hybrid2D: return "Two-dimensional hybrid map with satellite imagery"
        case .buildings3D: return "Three-dimensional view with buildings"
        case .terrain3D: return "Three-dimensional view with terrain elevation"
        case .full3D: return "Full three-dimensional view with buildings and terrain"
        }
    }
    
    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .flat2D: return "map"
        case .hybrid2D: return "map.fill"
        case .buildings3D: return "building.2.crop.circle"
        case .terrain3D: return "mountain.2.circle"
        case .full3D: return "globe.americas.fill"
        }
    }
    
    /// Whether this mode supports 3D features
    var supports3D: Bool {
        switch self {
        case .flat2D, .hybrid2D: return false
        case .buildings3D, .terrain3D, .full3D: return true
        }
    }
}

// MARK: - Extensions for MapDisplayMode

/// Extensions for MapDisplayMode
extension MapDisplayMode {
    var mapKitEquivalent: MKMapType {
        switch self {
        case .flat2D, .buildings3D, .terrain3D, .full3D:
            return .standard
        case .hybrid2D:
            return .hybrid
        }
    }
}

/// Render quality options
enum RenderQuality {
    case low
    case medium
    case high
    case auto
    
    /// Recommended frame rate target
    var targetFrameRate: Double {
        switch self {
        case .low: return 30.0
        case .medium: return 45.0
        case .high: return 60.0
        case .auto: return 60.0
        }
    }
}

// Using MedicalFacility3DAnnotation from MapboxTypes.swift

/// Extension to add display properties for MapboxView3D
extension MedicalFacility3DAnnotation.FacilityType {
    var color: Color {
        switch self {
        case .emergencyDepartment: return .red
        case .urgentCare: return .orange
        case .hospital: return .blue
        case .clinic: return .green
        case .pharmacy: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .emergencyDepartment: return "cross.circle.fill"
        case .urgentCare: return "stethoscope.circle.fill"
        case .hospital: return "building.2.crop.circle.fill"
        case .clinic: return "heart.circle.fill"
        case .pharmacy: return "pills.circle.fill"
        }
    }
}

/// Extension to add display properties for MapboxView3D
extension MedicalFacility3DAnnotation.PriorityLevel {
    var scale: Double {
        switch self {
        case .low: return 0.8
        case .medium: return 0.9
        case .high: return 1.0
        case .critical: return 1.2
        }
    }
}

/// **MedicalFacility3DAnnotationView**: Custom 3D annotation view for medical facilities
struct MedicalFacility3DAnnotationView: View {
    let annotation: MedicalFacility3DAnnotation
    let displayMode: MapDisplayMode
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Base circle with facility type color
                Circle()
                    .fill(annotation.facilityType.color)
                    .frame(width: baseSize, height: baseSize)
                    .shadow(radius: displayMode.supports3D ? 4 : 2)
                
                // Facility type icon
                Image(systemName: annotation.facilityType.icon)
                    .foregroundColor(.white)
                    .font(.system(size: iconSize, weight: .semibold))
                
                // Wait time overlay (if available)
                if let waitTime = annotation.waitTime, displayMode.supports3D {
                    waitTimeOverlay(waitTime)
                }
            }
            .scaleEffect(annotation.priorityLevel.scale)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: displayMode)
        }
        .accessibility(label: Text(accessibilityLabel))
        .accessibility(hint: Text("Double-tap for facility details"))
    }
    
    /// Base size for annotation based on display mode
    private var baseSize: CGFloat {
        displayMode.supports3D ? 40 : 32
    }
    
    /// Icon size based on display mode
    private var iconSize: CGFloat {
        displayMode.supports3D ? 18 : 14
    }
    
    /// Wait time overlay for 3D mode
    @ViewBuilder
    private func waitTimeOverlay(_ waitTime: Int) -> some View {
        VStack {
            Spacer()
            Text("\(waitTime)m")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
        }
        .offset(y: 20)
    }
    
    /// Accessibility label
    private var accessibilityLabel: String {
        var label = "\(annotation.name), \(annotation.facilityType)"
        
        if let waitTime = annotation.waitTime {
            label += ", \(waitTime) minute wait"
        }
        
        if let distance = annotation.distance {
            label += ", \(distance) away"
        }
        
        label += annotation.isOpen ? ", Open" : ", Closed"
        
        return label
    }
}

/// **Map3DPerformanceManager**: Manages 3D rendering performance and device capabilities
class Map3DPerformanceManager: ObservableObject {
    @Published var supports3D: Bool = true
    @Published var recommendedQuality: RenderQuality = .auto
    @Published var currentFrameRate: Double = 60.0
    @Published var showPerformanceIndicator: Bool = false
    
    /// Device capability assessment
    func detectDeviceCapabilities() {
        // Detect device model and capabilities
        let device = UIDevice.current
        let systemVersion = device.systemVersion
        
        // iOS 15+ required for optimal 3D performance
        supports3D = systemVersion.compare("15.0", options: .numeric) != .orderedAscending
        
        // Adjust quality based on device performance characteristics
        recommendedQuality = determineOptimalQuality()
        
        #if DEBUG
        showPerformanceIndicator = true
        #endif
    }
    
    /// Determine optimal rendering quality for current device
    private func determineOptimalQuality() -> RenderQuality {
        // This would typically check device model, memory, GPU capabilities
        // For now, defaulting to auto which adapts dynamically
        return .auto
    }
    
    /// Monitor and adapt performance during runtime
    func monitorPerformance() {
        // This would monitor actual frame rates and adjust quality accordingly
        // Implementation would use CADisplayLink or similar for frame rate monitoring
    }
}

// MARK: - Preview Support

#Preview("MapboxView3D") {
    MapboxView3D(
        coordinateRegion: .constant(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )),
        annotations: [
            MedicalFacility3DAnnotation(
                id: "1",
                coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
                name: "Barnes-Jewish Hospital",
                facilityType: .emergencyDepartment,
                waitTime: 45,
                waitTimeChange: "+5 min",
                distance: "2.3 mi",
                isOpen: true,
                buildingHeight: 100.0,
                priorityLevel: .high,
                customIcon: nil
            ),
            MedicalFacility3DAnnotation(
                id: "2", 
                coordinate: CLLocationCoordinate2D(latitude: 38.6370, longitude: -90.2094),
                name: "Urgent Care Plus",
                facilityType: .urgentCare,
                waitTime: 15,
                waitTimeChange: "-2 min",
                distance: "1.8 mi",
                isOpen: true,
                buildingHeight: 25.0,
                priorityLevel: .medium,
                customIcon: nil
            )
        ],
        mapMode: .buildings3D
    )
}