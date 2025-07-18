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
struct MapboxView: UIViewRepresentable {
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject {
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
    
    /// Callback for map tap events
    var onMapTap: ((CLLocationCoordinate2D) -> Void)?
    
    /// Callback for fly-to animation completion
    var onFlyToComplete: (() -> Void)?
    
    /// Callback for camera animation start
    var onCameraAnimationStart: (() -> Void)?
    
    /// Trigger for fly-to animation
    var flyToTrigger: FlyToTrigger?
    
    /// Mapbox access token
    private let accessToken = "pk.eyJ1IjoiY21pbHRvbjQiLCJhIjoiY21kNTVkcjh1MG05eTJrb21qeHB0aXo4bCJ9.5vv9akWMhonZ_J3ftkUKRg"
    
    // MARK: - UIViewRepresentable Implementation
    
    func makeUIView(context: Context) -> MapView {
        // Configure Mapbox with access token
        MapboxOptions.accessToken = accessToken
        
        // Create map view with initial camera
        let mapView = MapView(frame: .zero)
        
        // Set up Standard Core style with 3D features
        configureMapStyle(mapView: mapView)
        
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
        // Update camera region if changed
        updateCameraRegion(mapView: mapView)
        
        // Update annotations
        updateAnnotations(mapView: mapView)
        
        // Handle fly-to trigger
        if let trigger = flyToTrigger {
            context.coordinator.executeFlyTo(
                coordinate: trigger.coordinate,
                zoom: trigger.zoom,
                pitch: trigger.pitch,
                bearing: trigger.bearing,
                duration: trigger.duration
            )
        }
    }
    
    // MARK: - Configuration Methods
    
    /// Configure Mapbox Standard Core style with 3D features
    private func configureMapStyle(mapView: MapView) {
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
                
                // Set dynamic lighting based on time of day
                let lightPreset = self.getCurrentLightPreset()
                try mapView.mapboxMap.setStyleImportConfigProperty(
                    for: "basemap",
                    config: "lightPreset",
                    value: lightPreset
                )
                
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
        
        // Check if region has changed significantly
        let centerDistance = coordinateRegion.center.distance(from: currentCenter)
        let zoomLevel = getZoomLevel(from: coordinateRegion.span)
        
        if centerDistance > 100 || abs(currentZoom - zoomLevel) > 0.5 {
            let camera = CameraOptions(
                center: coordinateRegion.center,
                zoom: zoomLevel,
                bearing: mapView.mapboxMap.cameraState.bearing,
                pitch: mapView.mapboxMap.cameraState.pitch
            )
            
            // Use smooth animation for location updates
            if centerDistance > 500 { // Larger distance changes get animated
                mapView.camera.ease(to: camera, duration: 1.2)
            } else {
                mapView.mapboxMap.setCamera(to: camera)
            }
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
    
    // MARK: - Utility Methods
    
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