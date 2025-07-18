//
//  MapboxView.swift
//  STL Wait Times
//
//  Mapbox Standard Core Style Implementation
//  Created by Claude AI on 7/17/25.
//

import SwiftUI
import MapboxMaps
import MapKit
import CoreLocation

/// **FlyToTrigger**: Trigger structure for fly-to animations
struct FlyToTrigger: Equatable {
    let coordinate: CLLocationCoordinate2D
    let zoom: Double
    let pitch: Double
    let bearing: Double
    let duration: TimeInterval
    let id: UUID = UUID()
    
    static func == (lhs: FlyToTrigger, rhs: FlyToTrigger) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// Create a facility-focused fly-to trigger
    static func facility(_ annotation: CustomMapAnnotation) -> FlyToTrigger {
        return FlyToTrigger(
            coordinate: annotation.coordinate,
            zoom: 16.0,
            pitch: 60.0,
            bearing: 0.0,
            duration: 2.5
        )
    }
    
    /// Create an overview fly-to trigger
    static func overview(animated: Bool = true) -> FlyToTrigger {
        return FlyToTrigger(
            coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
            zoom: 12.0,
            pitch: 45.0,
            bearing: 0.0,
            duration: animated ? 3.0 : 0.0
        )
    }
}

/// **MapboxView**: Professional Mapbox integration with Standard Core style
///
/// **Features:**
/// - 🌍 Mapbox Standard Core style with 3D buildings and landmarks
/// - 🏗️ 3D urban environments and terrain
/// - 🎮 Smooth camera controls and animations
/// - 🎨 Dynamic lighting presets (day/dusk/night)
/// - ⚡ Optimized performance with native SDK
/// - ♿ Full accessibility support
/// - 📍 Custom annotation system for medical facilities
/// - 📱 Automatic user location centering with smooth animations
///
/// **Usage:**
/// ```swift
/// MapboxView(
///     coordinateRegion: $region,
///     annotations: medicalFacilities,
///     mapStyle: "standard",
///     onMapTap: { coordinate in
///         // Handle location tap
///     }
/// )
/// ```
struct MapboxView: UIViewRepresentable, Equatable {
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var lightTimer: Timer? = nil
        
        /// Schedule a timer that refreshes the light preset every 30 minutes.
        func scheduleLightRefresh(for mapView: MapView) {
            // Invalidate existing timer if any
            lightTimer?.invalidate()
            lightTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { _ in
                DispatchQueue.main.async {
                    // Re-evaluate time-of-day preset
                    do {
                        let preset = Calendar.current.component(.hour, from: Date())
                        print("🌗 Refreshing 3-D light preset, hour = \(preset)")
                    }
                    // Force style update via helper in parent
                    self.parent.updateLightPreset(for: mapView)
                }
            }
        }
        let parent: MapboxView
        private var mapView: MapView?
        
        init(_ parent: MapboxView) {
            self.parent = parent
        }
        
        func setMapView(_ mapView: MapView) {
            self.mapView = mapView
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MapView else { return }
            
            let point = gesture.location(in: mapView)
            let coordinate = mapView.mapboxMap.coordinate(for: point)
            
            parent.onMapTap?(coordinate)
        }
        
        /// Execute fly-to camera animation
        func executeFlyTo(
            coordinate: CLLocationCoordinate2D,
            zoom: Double = 14.0,
            pitch: Double = 45.0,
            bearing: Double = 0.0,
            duration: TimeInterval = 2.0
        ) {
            guard let mapView = self.mapView else { return }
            
            // Notify animation start
            parent.onCameraAnimationStart?()
            
            // Create target camera options
            let targetCamera = CameraOptions(
                center: coordinate,
                zoom: zoom,
                bearing: bearing,
                pitch: pitch
            )
            
            // Start the animation with completion handler
            mapView.camera.ease(to: targetCamera, duration: duration) { _ in
                DispatchQueue.main.async {
                    self.parent.onFlyToComplete?()
                }
            }
            
            // Announce for accessibility
            let announcement = "Flying to new location"
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
    
    // MARK: - Properties
    
    /// Coordinate region for the map
    @Binding var coordinateRegion: MKCoordinateRegion
    
    /// Medical facility annotations
    var annotations: [CustomMapAnnotation] = []
    
    /// Map style identifier (keeping for compatibility)
    var mapStyle: String = "standard"
    
    /// Whether dynamic 3-D lights are enabled
    var lightsEnabled: Bool = true
    
    /// Callback for map tap events
    var onMapTap: ((CLLocationCoordinate2D) -> Void)?
    
    /// Callback for fly-to animation completion
    var onFlyToComplete: (() -> Void)?
    
    /// Callback for camera animation start
    var onCameraAnimationStart: (() -> Void)?
    
    /// Trigger for fly-to animation
    var flyToTrigger: FlyToTrigger?
    
    /// Trigger for forcing recenter even when coordinates haven't changed
    var recenterTrigger: UUID?
    
    /// Mapbox access token
    private let accessToken = "pk.eyJ1IjoiY21pbHRvbjQiLCJhIjoiY21kNTVkcjh1MG05eTJrb21qeHB0aXo4bCJ9.5vv9akWMhonZ_J3ftkUKRg"
    
    
    // MARK: - Equatable Implementation
    
    static func == (lhs: MapboxView, rhs: MapboxView) -> Bool {
        // Compare the center coordinates to detect region changes
        let centerChanged = abs(lhs.coordinateRegion.center.latitude - rhs.coordinateRegion.center.latitude) > 0.0001 ||
                           abs(lhs.coordinateRegion.center.longitude - rhs.coordinateRegion.center.longitude) > 0.0001
        
        let spanChanged = abs(lhs.coordinateRegion.span.latitudeDelta - rhs.coordinateRegion.span.latitudeDelta) > 0.0001 ||
                         abs(lhs.coordinateRegion.span.longitudeDelta - rhs.coordinateRegion.span.longitudeDelta) > 0.0001
        
        // Check if recenter trigger changed
        let triggerChanged = lhs.recenterTrigger != rhs.recenterTrigger
        
        // Check if lights setting changed
        let lightsChanged = lhs.lightsEnabled != rhs.lightsEnabled
        
        // Return false if anything changed (this will trigger updateUIView)
        return !centerChanged && !spanChanged && lhs.annotations.count == rhs.annotations.count && !triggerChanged && !lightsChanged
    }
    
    // MARK: - UIViewRepresentable Implementation
    
    func makeUIView(context: Context) -> MapView {
        // Configure Mapbox with access token
        MapboxOptions.accessToken = accessToken
        
        // Create map view with initial camera
        let mapView = MapView(frame: .zero)
        
        // Set up Standard Core style with 3D features
        configureMapStyle(mapView: mapView, coordinator: context.coordinator)
        
        // Set up initial camera position
        setupInitialCamera(mapView: mapView)
        
        // Configure interactions
        setupMapInteractions(mapView: mapView, context: context)
        
        // Add accessibility
        setupAccessibility(mapView: mapView)
        
        // Store map view in coordinator for fly-to functionality
        context.coordinator.setMapView(mapView)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MapView, context: Context) {
        print("🔄 MapboxView updateUIView called")
        
        // Get detailed state information for debugging
        let currentCenter = mapView.mapboxMap.cameraState.center
        let targetCenter = coordinateRegion.center
        
        print("🔍 Current map center: \(currentCenter.latitude), \(currentCenter.longitude)")
        print("🔍 Target region center: \(targetCenter.latitude), \(targetCenter.longitude)")
        print("🔍 Current lights: \(lightsEnabled)")
        print("🔍 Recenter trigger: \(recenterTrigger?.uuidString ?? "nil")")
        
        let centerLatDiff = abs(targetCenter.latitude - currentCenter.latitude)
        let centerLonDiff = abs(targetCenter.longitude - currentCenter.longitude)
        let centerChanged = centerLatDiff > 0.0001 || centerLonDiff > 0.0001
        
        print("🔍 Center differences - Lat: \(centerLatDiff), Lon: \(centerLonDiff)")
        print("🔍 Center changed: \(centerChanged)")
        
        // COMPLETELY SKIP camera updates for ANY lights-only changes
        // Only update camera for explicit recenter triggers or if this is NOT a lights-only change
        if recenterTrigger != nil {
            print("🎯 Explicit recenter trigger - updating camera")
            updateCameraRegion(mapView: mapView)
        } else if centerChanged {
            print("❓ Center changed but no recenter trigger - might be unintended")
            print("❓ Skipping camera update to prevent unwanted recentering")
            // updateCameraRegion(mapView: mapView) // COMMENTED OUT for now
        } else {
            print("✅ No camera changes needed")
        }
        
        // Update annotations
        updateAnnotations(mapView: mapView)
        
        // Always update 3D lights (was missing from original - this fixes lights toggle!)
        configure3DLights(for: mapView)
        
        // Handle fly-to trigger
        if let trigger = flyToTrigger {
            print("✈️ Executing fly-to animation")
            context.coordinator.executeFlyTo(
                coordinate: trigger.coordinate,
                zoom: trigger.zoom,
                pitch: trigger.pitch,
                bearing: trigger.bearing,
                duration: trigger.duration
            )
        }
        
        // Handle recenter trigger
        if let _ = recenterTrigger {
            print("🎯 Executing recenter animation")
            context.coordinator.executeFlyTo(
                coordinate: coordinateRegion.center,
                zoom: getZoomLevel(from: coordinateRegion.span),
                pitch: 45.0,
                bearing: 0.0,
                duration: 1.5
            )
        }
    }
    
    // MARK: - Configuration Methods
    
    /// Configure Mapbox Standard Core style with 3D features
    private func configureMapStyle(mapView: MapView, coordinator: Coordinator) {
        // Cancel any existing timer each time we rebuild style
        coordinator.lightTimer?.invalidate()
        coordinator.lightTimer = nil
        // Set Standard Core style
        mapView.mapboxMap.styleURI = .standard
        
        // Configure Standard style properties for enhanced 3D experience
        _ = mapView.mapboxMap.onStyleLoaded.observeNext { _ in
            do {
                // Enable 3D buildings and objects
                try mapView.mapboxMap.setStyleImportConfigProperty(
                    for: "basemap",
                    config: "show3dObjects",
                    value: true
                )
                
                // Configure 3D lighting using Mapbox's experimental style content API
                self.configure3DLights(for: mapView)
                
                if self.lightsEnabled {
                    // Schedule timer to refresh lights every 30 minutes for dynamic lighting
                    coordinator.scheduleLightRefresh(for: mapView)
                }
                
                // Configure label visibility for medical facilities
                try mapView.mapboxMap.setStyleImportConfigProperty(
                    for: "basemap",
                    config: "showPointOfInterestLabels",
                    value: true
                )
                
                try mapView.mapboxMap.setStyleImportConfigProperty(
                    for: "basemap",
                    config: "showPlaceLabels",
                    value: true
                )
                
                try mapView.mapboxMap.setStyleImportConfigProperty(
                    for: "basemap",
                    config: "showRoadLabels",
                    value: true
                )
                
                try mapView.mapboxMap.setStyleImportConfigProperty(
                    for: "basemap",
                    config: "showTransitLabels",
                    value: false
                )
                
                print("✅ Mapbox Standard Core style configured successfully")
            } catch {
                print("❌ Error configuring Mapbox Standard style properties: \(error)")
            }
        }
    }
    
    /// Set up initial camera position
    private func setupInitialCamera(mapView: MapView) {
        let camera = CameraOptions(
            center: coordinateRegion.center,
            zoom: getZoomLevel(from: coordinateRegion.span),
            bearing: 0,
            pitch: 45 // Add pitch for 3D view
        )
        
        mapView.mapboxMap.setCamera(to: camera)
    }
    
    /// Set up map interactions and gestures
    private func setupMapInteractions(mapView: MapView, context: Context) {
        // Add tap gesture recognizer for map taps
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
    }
    
    /// Set up accessibility features
    private func setupAccessibility(mapView: MapView) {
        mapView.isAccessibilityElement = true
        mapView.accessibilityLabel = "3D map with medical facilities"
        mapView.accessibilityHint = "Double-tap to interact with locations"
        mapView.accessibilityTraits = [.allowsDirectInteraction]
    }
    
    // MARK: - Update Methods
    
    /// Update camera region when binding changes
    private func updateCameraRegion(mapView: MapView) {
        let currentCenter = mapView.mapboxMap.cameraState.center
        let currentZoom = mapView.mapboxMap.cameraState.zoom
        
        print("🗺️ MapboxView updateCameraRegion called")
        print("🗺️ Current center: \(currentCenter.latitude), \(currentCenter.longitude)")
        print("🗺️ Target center: \(coordinateRegion.center.latitude), \(coordinateRegion.center.longitude)")
        
        // Check if region has changed significantly
        let centerDistance = coordinateRegion.center.distance(from: currentCenter)
        let zoomLevel = getZoomLevel(from: coordinateRegion.span)
        
        print("🗺️ Distance: \(centerDistance) meters")
        print("🗺️ Current zoom: \(currentZoom), Target zoom: \(zoomLevel)")
        
        if centerDistance > 100 || abs(currentZoom - zoomLevel) > 0.5 {
            print("✅ Updating MapboxView camera (distance: \(centerDistance)m)")
            
            let camera = CameraOptions(
                center: coordinateRegion.center,
                zoom: zoomLevel,
                bearing: mapView.mapboxMap.cameraState.bearing,
                pitch: mapView.mapboxMap.cameraState.pitch
            )
            
            // Use smooth animation for location updates
            if centerDistance > 500 { // Larger distance changes get animated
                print("🎬 Using animated camera update")
                mapView.camera.ease(to: camera, duration: 1.2)
            } else {
                print("⚡ Using instant camera update")
                mapView.mapboxMap.setCamera(to: camera)
            }
        } else {
            print("⚠️ Not updating camera - distance too small (\(centerDistance)m) or zoom difference too small")
        }
    }
    
    /// Update annotations on the map
    private func updateAnnotations(mapView: MapView) {
        // Remove existing annotations
        try? mapView.mapboxMap.removeSource(withId: "medical-facilities")
        
        // Add new annotations if any
        if !annotations.isEmpty {
            addMedicalFacilityAnnotations(mapView: mapView)
        }
    }
    
    /// Add medical facility annotations to the map
    private func addMedicalFacilityAnnotations(mapView: MapView) {
        // Create GeoJSON features for medical facilities
        let features = annotations.map { annotation in
            Feature(geometry: Point(annotation.coordinate))
        }
        
        let featureCollection = FeatureCollection(features: features)
        
        // Add GeoJSON source
        var geoJSONSource = GeoJSONSource(id: "medical-facilities")
        geoJSONSource.data = .featureCollection(featureCollection)
        
        do {
            try mapView.mapboxMap.addSource(geoJSONSource)
            
            // Create symbol layer for medical facilities
            var symbolLayer = SymbolLayer(id: "medical-facilities-layer", source: "medical-facilities")
            symbolLayer.iconImage = .constant(.name("hospital"))
            symbolLayer.iconSize = .constant(1.5)
            symbolLayer.iconAnchor = .constant(.bottom)
            symbolLayer.slot = .middle // Place in middle slot for proper 3D layering
            
            try mapView.mapboxMap.addLayer(symbolLayer)
            
            // Facility tap handling is managed by the general tap gesture
            
        } catch {
            print("Error adding medical facility annotations: \(error)")
        }
    }
    
    // MARK: - Lighting Helpers
    
    /// Update 3D lights for mapView
    private func updateLightPreset(for mapView: MapView) {
        // Reconfigure 3D lights with current time-based parameters
        configure3DLights(for: mapView)
        print(" Updated 3D lights based on current time")
    }
    
    // MARK: - Utility Methods
    
    /// Configure 3D lights using Mapbox's experimental style content API
    private func configure3DLights(for mapView: MapView) {
        let hour = Calendar.current.component(.hour, from: Date())
        print("🔆 configure3DLights called - lightsEnabled: \(lightsEnabled), hour: \(hour)")
        
        // Calculate dynamic light parameters based on time of day
        let (azimuth, polarAngle, intensity, ambientColor) = getLightParameters(for: hour)
        print("💡 Light params - azimuth: \(azimuth), polar: \(polarAngle), intensity: \(intensity)")
        
        do {
            // Try multiple possible import names for Mapbox Standard style
            let possibleImports = ["standard", "basemap", "mapbox"]
            var lightPresetSet = false
            
            for importName in possibleImports {
                do {
                    let preset = lightsEnabled ? "day" : getCurrentLightPreset()
                    try mapView.mapboxMap.setStyleImportConfigProperty(
                        for: importName,
                        config: "lightPreset",
                        value: preset
                    )
                    print("✅ Successfully set lightPreset to: \(preset) using import: \(importName)")
                    lightPresetSet = true
                    break
                } catch {
                    print("⚠️ Failed to set lightPreset with import '\(importName)': \(error)")
                }
            }
            
            if !lightPresetSet {
                print("❌ Could not set lightPreset with any known import name")
            }
            
            // Also try the experimental style content API
            mapView.mapboxMap.setMapStyleContent {
                // Configure atmospheric rendering
                Atmosphere()
                    .range(start: 0, end: 12)
                    .horizonBlend(0.1)
                    .starIntensity(lightsEnabled ? 0.0 : 0.2)
                    .color(StyleColor(red: 240, green: 196, blue: 152, alpha: 1)!)
                    .highColor(StyleColor(red: 221, green: 209, blue: 197, alpha: 1)!)
                    .spaceColor(StyleColor(red: 153, green: 180, blue: 197, alpha: 1)!)
                
                // Configure directional light (sun)
                DirectionalLight(id: "directional-light")
                    .intensity(lightsEnabled ? 0.8 : intensity)
                    .direction(azimuthal: azimuth, polar: polarAngle)
                    .directionTransition(.zero)
                    .castShadows(lightsEnabled)
                    .shadowIntensity(lightsEnabled ? 1.0 : 0.0)
                
                // Configure ambient light
                AmbientLight(id: "ambient-light")
                    .color(ambientColor)
                    .intensity(lightsEnabled ? 0.6 : 0.2)
            }
            print("✅ Successfully configured experimental 3D lights")
            
        } catch {
            print("❌ Failed to configure 3D lights: \(error)")
        }
    }
    
    /// Get lighting parameters based on time of day
    private func getLightParameters(for hour: Int) -> (azimuth: Double, polarAngle: Double, intensity: Double, ambientColor: UIColor) {
        switch hour {
        case 6..<8: // Dawn
            return (azimuth: 120.0, polarAngle: 15.0, intensity: 0.3, ambientColor: UIColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1.0))
        case 8..<10: // Morning
            return (azimuth: 140.0, polarAngle: 25.0, intensity: 0.6, ambientColor: UIColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0))
        case 10..<15: // Midday
            return (azimuth: 180.0, polarAngle: 45.0, intensity: 0.8, ambientColor: UIColor.white)
        case 15..<17: // Afternoon
            return (azimuth: 220.0, polarAngle: 35.0, intensity: 0.7, ambientColor: UIColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1.0))
        case 17..<19: // Dusk
            return (azimuth: 250.0, polarAngle: 20.0, intensity: 0.4, ambientColor: UIColor(red: 1.0, green: 0.7, blue: 0.4, alpha: 1.0))
        case 19..<22: // Evening
            return (azimuth: 270.0, polarAngle: 10.0, intensity: 0.2, ambientColor: UIColor(red: 0.8, green: 0.6, blue: 0.8, alpha: 1.0))
        default: // Night
            return (azimuth: 0.0, polarAngle: 5.0, intensity: 0.1, ambientColor: UIColor(red: 0.5, green: 0.5, blue: 0.7, alpha: 1.0))
        }
    }
    
    /// Get current light preset based on time of day
    private func getCurrentLightPreset() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6..<10:
            return "dawn"
        case 10..<17:
            return "day"
        case 17..<20:
            return "dusk"
        default:
            return "night"
        }
    }
    
    /// Convert MKCoordinateSpan to Mapbox zoom level
    private func getZoomLevel(from span: MKCoordinateSpan) -> Double {
        // Approximate zoom level calculation
        let longitudeDelta = span.longitudeDelta
        let zoom = log2(360.0 / longitudeDelta)
        
        return max(1.0, min(zoom, 20.0))
    }
}

// MARK: - Fly-To Animation Methods

extension MapboxView {
    
    /// Fly to a specific location with smooth animation
    /// - Parameters:
    ///   - coordinate: Target coordinate
    ///   - zoom: Target zoom level (default: 14.0)
    ///   - pitch: Camera pitch in degrees (default: 45.0 for 3D view)
    ///   - bearing: Camera bearing in degrees (default: 0.0)
    ///   - duration: Animation duration in seconds (default: 2.0)
    ///   - coordinator: The coordinator instance to execute the animation
    static func flyToLocation(
        coordinator: Coordinator,
        coordinate: CLLocationCoordinate2D,
        zoom: Double = 14.0,
        pitch: Double = 45.0,
        bearing: Double = 0.0,
        duration: TimeInterval = 2.0
    ) {
        coordinator.executeFlyTo(
            coordinate: coordinate,
            zoom: zoom,
            pitch: pitch,
            bearing: bearing,
            duration: duration
        )
    }
    
    /// Fly to a medical facility with optimal viewing angle
    /// - Parameters:
    ///   - coordinator: The coordinator instance to execute the animation
    ///   - annotation: Medical facility annotation
    ///   - completion: Completion callback
    static func flyToFacility(
        coordinator: Coordinator,
        annotation: CustomMapAnnotation,
        completion: @escaping () -> Void = {}
    ) {
        coordinator.executeFlyTo(
            coordinate: annotation.coordinate,
            zoom: 16.0,
            pitch: 60.0,
            bearing: 0.0,
            duration: 2.5
        )
        
        // Call completion after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            completion()
        }
    }
    
    /// Return to St. Louis overview with smooth animation
    /// - Parameters:
    ///   - coordinator: The coordinator instance to execute the animation
    ///   - animated: Whether to animate the transition
    static func returnToOverview(coordinator: Coordinator, animated: Bool = true) {
        let stLouisOverview = CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994)
        let duration: TimeInterval = animated ? 3.0 : 0.0
        
        coordinator.executeFlyTo(
            coordinate: stLouisOverview,
            zoom: 12.0,
            pitch: 45.0,
            bearing: 0.0,
            duration: duration
        )
    }
}

// MARK: - Supporting Types and Extensions

/// Custom map annotation for medical facilities
struct CustomMapAnnotation: Identifiable, Equatable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let color: UIColor
    let title: String?
    let subtitle: String?
    
    init(id: String, 
         coordinate: CLLocationCoordinate2D, 
         color: UIColor, 
         title: String? = nil, 
         subtitle: String? = nil) {
        self.id = id
        self.coordinate = coordinate
        self.color = color
        self.title = title
        self.subtitle = subtitle
    }
    
    static func == (lhs: CustomMapAnnotation, rhs: CustomMapAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

/// Extension for coordinate distance calculation
extension CLLocationCoordinate2D {
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
}

// MARK: - Preview Support

#Preview("Mapbox Standard Core") {
    @Previewable @State var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994), // St. Louis
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    let sampleAnnotations = [
        CustomMapAnnotation(
            id: "hospital1",
            coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
            color: .systemRed,
            title: "Sample Hospital",
            subtitle: "Emergency Department"
        )
    ]
    
    return MapboxView(
        coordinateRegion: $region,
        annotations: sampleAnnotations,
        mapStyle: "standard",
        onMapTap: { coordinate in
            print("Tapped at: \(coordinate)")
        }
    )
}