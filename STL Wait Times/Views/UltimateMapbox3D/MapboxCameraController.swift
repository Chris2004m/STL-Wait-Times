//
//  MapboxCameraController.swift
//  STL Wait Times
//
//  Advanced camera control system for Ultimate 3D Mapbox component
//  Created by SuperClaude Enterprise Framework on 7/16/25.
//

import SwiftUI
import CoreLocation
import MapKit
import Combine

/// **MapboxCameraController**: Enterprise-grade camera control and animation system
///
/// **Features:**
/// - 🎮 Smooth camera animations with customizable easing
/// - 📐 Precision camera positioning (pitch, bearing, zoom, altitude)
/// - 🔄 Seamless 2D/3D transitions
/// - ♿ Accessibility-aware motion controls
/// - 🎯 Intelligent auto-framing for medical facilities
/// - 📱 Multi-touch gesture recognition and handling
/// - ⚡ Performance-optimized camera updates
///
/// **Camera States:**
/// ```
/// CameraState
/// ├── position: CLLocationCoordinate2D
/// ├── zoom: Double (2.0-20.0)
/// ├── pitch: Double (0.0-60.0°)
/// ├── bearing: Double (0.0-360.0°)
/// ├── altitude: Double (500.0-10000.0m)
/// └── mode: CameraMode (.flat, .tilted, .full3D)
/// ```
class MapboxCameraController: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current camera state with all positioning information
    @Published var cameraState: MapboxCameraState = .default
    
    /// MapKit-compatible region for fallback rendering
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    /// Current camera mode (flat, tilted, full 3D)
    @Published var cameraMode: CameraMode = .tilted
    
    /// Animation state for UI feedback
    @Published var isAnimating: Bool = false
    
    /// Gesture interaction state
    @Published var isUserInteracting: Bool = false
    
    // MARK: - Configuration Properties
    
    /// Initial camera state for reset functionality
    private var initialCameraState: MapboxCameraState = .default
    
    /// View bounds for gesture calculations
    private var viewBounds: CGSize = CGSize(width: 375, height: 812)
    
    /// Animation configuration
    private var animationConfiguration: CameraAnimationConfiguration = .smooth
    
    /// Accessibility settings
    private var accessibilityConfiguration: CameraAccessibilityConfiguration = .standard
    
    // MARK: - Callbacks
    
    /// Called when camera state changes significantly
    var onSignificantChange: ((MapboxCameraState) -> Void)?
    
    /// Called when 2D/3D mode changes
    var onModeChanged: ((CameraMode) -> Void)?
    
    /// Called when animation completes
    var onAnimationComplete: (() -> Void)?
    
    // MARK: - Private Properties
    
    /// Gesture recognizers
    private var panGesture: UIPanGestureRecognizer?
    private var pinchGesture: UIPinchGestureRecognizer?
    private var rotationGesture: UIRotationGestureRecognizer?
    
    /// Animation timers and state
    private var animationTimer: Timer?
    private var animationStartTime: Date?
    private var animationDuration: TimeInterval = 0.0
    private var fromState: MapboxCameraState?
    private var toState: MapboxCameraState?
    
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// Animation constraints
    private let constraints = CameraConstraints()
    
    // MARK: - Initialization
    
    init() {
        setupCameraStateObservation()
    }
    
    // MARK: - Public Configuration
    
    /// Configure camera controller with initial state and bounds
    func configure(initialState: MapboxCameraState, bounds: CGSize) {
        self.initialCameraState = initialState
        self.cameraState = initialState
        self.viewBounds = bounds
        
        // Update region for MapKit compatibility
        updateRegionFromCameraState()
        
        // Determine camera mode from initial state
        determineCameraModeFromState()
        
        print("📷 CameraController: Configured with initial state at \(initialState.center)")
    }
    
    /// Update camera controller configuration
    func updateConfiguration(_ newInitialState: MapboxCameraState) {
        self.initialCameraState = newInitialState
        configure(initialState: newInitialState, bounds: viewBounds)
    }
    
    /// Disable animations for reduced motion accessibility
    func disableAnimations() {
        animationConfiguration = .none
        stopCurrentAnimation()
    }
    
    // MARK: - Camera Positioning
    
    /// Set camera position with optional animation
    func setCameraPosition(
        center: CLLocationCoordinate2D,
        zoom: Double? = nil,
        pitch: Double? = nil,
        bearing: Double? = nil,
        altitude: Double? = nil,
        animated: Bool = true,
        duration: TimeInterval? = nil,
        completion: (() -> Void)? = nil
    ) {
        let newState = MapboxCameraState(
            center: center,
            zoom: zoom ?? cameraState.zoom,
            pitch: pitch ?? cameraState.pitch,
            bearing: bearing ?? cameraState.bearing,
            altitude: altitude ?? cameraState.altitude,
            is3D: (pitch ?? cameraState.pitch) > 0 || (bearing ?? cameraState.bearing) != 0
        )
        
        setCameraState(newState, animated: animated, duration: duration, completion: completion)
    }
    
    /// Set complete camera state with animation
    func setCameraState(
        _ newState: MapboxCameraState,
        animated: Bool = true,
        duration: TimeInterval? = nil,
        completion: (() -> Void)? = nil
    ) {
        // Apply constraints
        let constrainedState = constraints.apply(to: newState)
        
        if animated && animationConfiguration != CameraAnimationConfiguration.none {
            animateToState(
                constrainedState,
                duration: duration ?? animationConfiguration.defaultDuration,
                completion: completion
            )
        } else {
            // Immediate update
            updateCameraStateImmediate(constrainedState)
            completion?()
        }
    }
    
    /// Reset camera to initial position
    func resetToInitialPosition(completion: (() -> Void)? = nil) {
        setCameraState(
            initialCameraState,
            animated: true,
            duration: animationConfiguration.resetDuration,
            completion: completion
        )
    }
    
    // MARK: - Camera Mode Control
    
    /// Toggle between 2D and 3D camera modes
    func toggle3DMode(animated: Bool = true) {
        let newMode: CameraMode = cameraMode == .flat ? .full3D : .flat
        setCameraMode(newMode, animated: animated)
    }
    
    /// Set specific camera mode
    func setCameraMode(_ mode: CameraMode, animated: Bool = true) {
        let newState = mode.appliedTo(cameraState)
        setCameraState(newState, animated: animated) { [weak self] in
            self?.cameraMode = mode
            self?.onModeChanged?(mode)
        }
    }
    
    // MARK: - Zoom Controls
    
    /// Zoom in by one level
    func zoomIn(animated: Bool = true) {
        let newZoom = min(cameraState.zoom + 1.0, constraints.maxZoom)
        setCameraPosition(
            center: cameraState.center,
            zoom: newZoom,
            animated: animated
        )
    }
    
    /// Zoom out by one level
    func zoomOut(animated: Bool = true) {
        let newZoom = max(cameraState.zoom - 1.0, constraints.minZoom)
        setCameraPosition(
            center: cameraState.center,
            zoom: newZoom,
            animated: animated
        )
    }
    
    /// Set specific zoom level
    func setZoom(_ zoom: Double, animated: Bool = true) {
        let constrainedZoom = max(constraints.minZoom, min(zoom, constraints.maxZoom))
        setCameraPosition(
            center: cameraState.center,
            zoom: constrainedZoom,
            animated: animated
        )
    }
    
    // MARK: - Bearing and Pitch Controls
    
    /// Set camera bearing (rotation)
    func setBearing(_ bearing: Double, animated: Bool = true) {
        let normalizedBearing = bearing.truncatingRemainder(dividingBy: 360.0)
        setCameraPosition(
            center: cameraState.center,
            bearing: normalizedBearing,
            animated: animated
        )
    }
    
    /// Set camera pitch (tilt angle)
    func setPitch(_ pitch: Double, animated: Bool = true) {
        let constrainedPitch = max(constraints.minPitch, min(pitch, constraints.maxPitch))
        setCameraPosition(
            center: cameraState.center,
            pitch: constrainedPitch,
            animated: animated
        )
    }
    
    /// Reset bearing to north
    func resetBearing(animated: Bool = true) {
        setBearing(0.0, animated: animated)
    }
    
    // MARK: - Intelligent Framing
    
    /// Auto-frame multiple locations with optimal camera positioning
    func frameLocations(
        _ coordinates: [CLLocationCoordinate2D],
        padding: UIEdgeInsets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        guard !coordinates.isEmpty else {
            completion?()
            return
        }
        
        if coordinates.count == 1 {
            // Single location - just center on it
            setCameraPosition(
                center: coordinates[0],
                zoom: 15.0,
                animated: animated,
                completion: completion
            )
            return
        }
        
        // Calculate optimal bounds and camera position
        let optimalFrame = calculateOptimalFrame(for: coordinates, padding: padding)
        
        setCameraState(optimalFrame, animated: animated, completion: completion)
    }
    
    /// Frame medical facilities with intelligent prioritization
    func frameMedicalFacilities(
        _ annotations: [AdvancedMapAnnotation],
        prioritizeByWaitTime: Bool = true,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let coordinates = annotations.map { $0.coordinate }
        
        // If prioritizing by wait time, adjust framing to emphasize low wait times
        if prioritizeByWaitTime {
            let sortedAnnotations = annotations.sorted { annotation1, annotation2 in
                // Extract wait times for comparison
                let waitTime1 = extractWaitTime(from: annotation1)
                let waitTime2 = extractWaitTime(from: annotation2)
                return waitTime1 < waitTime2
            }
            
            // Focus on the best wait time locations
            let priorityCoordinates = Array(sortedAnnotations.prefix(3)).map { $0.coordinate }
            frameLocations(priorityCoordinates, animated: animated, completion: completion)
        } else {
            frameLocations(coordinates, animated: animated, completion: completion)
        }
    }
    
    // MARK: - Animation System
    
    /// Animate to new camera state with easing
    private func animateToState(
        _ targetState: MapboxCameraState,
        duration: TimeInterval,
        completion: (() -> Void)? = nil
    ) {
        // Stop any current animation
        stopCurrentAnimation()
        
        // Setup animation
        fromState = cameraState
        toState = targetState
        animationStartTime = Date()
        animationDuration = duration
        isAnimating = true
        
        // Start animation timer
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
        
        // Store completion callback
        onAnimationComplete = completion
    }
    
    /// Update animation frame
    private func updateAnimation() {
        guard let startTime = animationStartTime,
              let from = fromState,
              let to = toState else {
            stopCurrentAnimation()
            return
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let progress = min(elapsed / animationDuration, 1.0)
        
        // Apply easing function
        let easedProgress = animationConfiguration.easingFunction(progress)
        
        // Interpolate camera state
        let interpolatedState = interpolateCameraState(from: from, to: to, progress: easedProgress)
        
        // Update camera state
        updateCameraStateImmediate(interpolatedState)
        
        // Check if animation is complete
        if progress >= 1.0 {
            stopCurrentAnimation()
            onAnimationComplete?()
            onAnimationComplete = nil
        }
    }
    
    /// Stop current animation
    private func stopCurrentAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        animationStartTime = nil
        fromState = nil
        toState = nil
        isAnimating = false
    }
    
    // MARK: - Private Helper Methods
    
    /// Update camera state immediately without animation
    private func updateCameraStateImmediate(_ newState: MapboxCameraState) {
        let previousState = cameraState
        cameraState = newState
        
        // Update MapKit region
        updateRegionFromCameraState()
        
        // Determine camera mode
        determineCameraModeFromState()
        
        // Check for significant changes
        if isSignificantChange(from: previousState, to: newState) {
            onSignificantChange?(newState)
        }
    }
    
    /// Update MapKit region from camera state
    private func updateRegionFromCameraState() {
        region = cameraState.mapKitRegion
    }
    
    /// Determine camera mode from current state
    private func determineCameraModeFromState() {
        if cameraState.pitch == 0 && cameraState.bearing == 0 {
            cameraMode = .flat
        } else if cameraState.pitch > 0 && cameraState.pitch < 30 {
            cameraMode = .tilted
        } else {
            cameraMode = .full3D
        }
    }
    
    /// Check if camera change is significant enough to trigger callbacks
    private func isSignificantChange(from: MapboxCameraState, to: MapboxCameraState) -> Bool {
        let centerChange = from.center.distance(to: to.center) > 100 // 100 meters
        let zoomChange = abs(from.zoom - to.zoom) > 0.5
        let pitchChange = abs(from.pitch - to.pitch) > 5.0
        let bearingChange = abs(from.bearing - to.bearing) > 10.0
        
        return centerChange || zoomChange || pitchChange || bearingChange
    }
    
    /// Calculate optimal frame for multiple coordinates
    private func calculateOptimalFrame(
        for coordinates: [CLLocationCoordinate2D],
        padding: UIEdgeInsets
    ) -> MapboxCameraState {
        // Calculate bounding box
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        // Calculate center
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        
        // Calculate optimal zoom
        let latDelta = maxLat - minLat
        let lonDelta = maxLon - minLon
        let maxDelta = max(latDelta, lonDelta)
        
        // Apply padding factor
        let paddingFactor = 1.5
        let adjustedDelta = maxDelta * paddingFactor
        
        let zoom = max(2.0, min(18.0, 14.0 - log2(adjustedDelta * 100)))
        
        return MapboxCameraState(
            center: center,
            zoom: zoom,
            pitch: coordinates.count > 1 ? 30.0 : 0.0,
            bearing: 0.0,
            altitude: 2000.0,
            is3D: coordinates.count > 1
        )
    }
    
    /// Extract wait time from annotation for prioritization
    private func extractWaitTime(from annotation: AdvancedMapAnnotation) -> Int {
        if case .medicalFacility(let data) = annotation.annotationType {
            return data.waitTime ?? Int.max
        }
        return Int.max
    }
    
    /// Interpolate between two camera states
    private func interpolateCameraState(
        from: MapboxCameraState,
        to: MapboxCameraState,
        progress: Double
    ) -> MapboxCameraState {
        let lat = from.center.latitude + (to.center.latitude - from.center.latitude) * progress
        let lon = from.center.longitude + (to.center.longitude - from.center.longitude) * progress
        let zoom = from.zoom + (to.zoom - from.zoom) * progress
        let pitch = from.pitch + (to.pitch - from.pitch) * progress
        let bearing = interpolateBearing(from: from.bearing, to: to.bearing, progress: progress)
        let altitude = from.altitude + (to.altitude - from.altitude) * progress
        
        return MapboxCameraState(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            zoom: zoom,
            pitch: pitch,
            bearing: bearing,
            altitude: altitude,
            is3D: to.is3D
        )
    }
    
    /// Interpolate bearing with proper 360-degree handling
    private func interpolateBearing(from: Double, to: Double, progress: Double) -> Double {
        var delta = to - from
        
        // Handle 360-degree wraparound
        if delta > 180 {
            delta -= 360
        } else if delta < -180 {
            delta += 360
        }
        
        let result = from + delta * progress
        return result.truncatingRemainder(dividingBy: 360.0)
    }
    
    /// Setup camera state observation
    private func setupCameraStateObservation() {
        $cameraState
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] newState in
                self?.updateRegionFromCameraState()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Types

/// **CameraMode**: Camera visualization modes
enum CameraMode: String, CaseIterable {
    case flat = "flat"
    case tilted = "tilted"
    case full3D = "full3D"
    
    var displayName: String {
        switch self {
        case .flat: return "2D View"
        case .tilted: return "Tilted View"
        case .full3D: return "3D View"
        }
    }
    
    var iconName: String {
        switch self {
        case .flat: return "map"
        case .tilted: return "map.fill"
        case .full3D: return "globe.americas.fill"
        }
    }
    
    /// Apply this mode to a camera state
    func appliedTo(_ state: MapboxCameraState) -> MapboxCameraState {
        switch self {
        case .flat:
            return MapboxCameraState(
                center: state.center,
                zoom: state.zoom,
                pitch: 0.0,
                bearing: 0.0,
                altitude: state.altitude,
                is3D: false
            )
        case .tilted:
            return MapboxCameraState(
                center: state.center,
                zoom: state.zoom,
                pitch: 30.0,
                bearing: state.bearing,
                altitude: state.altitude,
                is3D: true
            )
        case .full3D:
            return MapboxCameraState(
                center: state.center,
                zoom: state.zoom,
                pitch: 45.0,
                bearing: state.bearing,
                altitude: state.altitude,
                is3D: true
            )
        }
    }
}

/// **CameraConstraints**: Constraints for camera positioning
struct CameraConstraints {
    let minZoom: Double = 2.0
    let maxZoom: Double = 20.0
    let minPitch: Double = 0.0
    let maxPitch: Double = 60.0
    let minAltitude: Double = 500.0
    let maxAltitude: Double = 10000.0
    
    /// Apply constraints to camera state
    func apply(to state: MapboxCameraState) -> MapboxCameraState {
        return MapboxCameraState(
            center: state.center,
            zoom: max(minZoom, min(state.zoom, maxZoom)),
            pitch: max(minPitch, min(state.pitch, maxPitch)),
            bearing: state.bearing.truncatingRemainder(dividingBy: 360.0),
            altitude: max(minAltitude, min(state.altitude, maxAltitude)),
            is3D: state.is3D
        )
    }
}

/// **CameraAnimationConfiguration**: Animation settings and easing functions
struct CameraAnimationConfiguration: Equatable {
    let defaultDuration: TimeInterval
    let resetDuration: TimeInterval
    let easingFunction: (Double) -> Double
    
    static func == (lhs: CameraAnimationConfiguration, rhs: CameraAnimationConfiguration) -> Bool {
        return lhs.defaultDuration == rhs.defaultDuration && lhs.resetDuration == rhs.resetDuration
    }
    
    static let none = CameraAnimationConfiguration(
        defaultDuration: 0.0,
        resetDuration: 0.0,
        easingFunction: { $0 }
    )
    
    static let smooth = CameraAnimationConfiguration(
        defaultDuration: 0.8,
        resetDuration: 1.2,
        easingFunction: { progress in
            // Ease in-out cubic
            return progress < 0.5
                ? 4 * progress * progress * progress
                : 1 - pow(-2 * progress + 2, 3) / 2
        }
    )
    
    static let fast = CameraAnimationConfiguration(
        defaultDuration: 0.4,
        resetDuration: 0.6,
        easingFunction: { progress in
            // Ease out quad
            return 1 - (1 - progress) * (1 - progress)
        }
    )
}

/// **CameraAccessibilityConfiguration**: Accessibility settings for camera control
struct CameraAccessibilityConfiguration {
    let reduceMotion: Bool
    let enableVoiceOver: Bool
    let hapticFeedback: Bool
    
    static let standard = CameraAccessibilityConfiguration(
        reduceMotion: false,
        enableVoiceOver: true,
        hapticFeedback: true
    )
    
    static let accessible = CameraAccessibilityConfiguration(
        reduceMotion: true,
        enableVoiceOver: true,
        hapticFeedback: true
    )
}

// MARK: - Core Location Extensions

extension CLLocationCoordinate2D {
    /// Calculate distance to another coordinate in meters
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
}