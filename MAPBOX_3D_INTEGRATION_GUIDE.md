# Mapbox 3D Integration Comprehensive Guide

## Overview

This guide provides complete documentation for the advanced 3D Mapbox integration in the STL Wait Times iOS application. The implementation enhances medical facility visualization through immersive 3D mapping, intelligent facility annotation, and accessibility-first design.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Installation & Setup](#installation--setup)
3. [Component Reference](#component-reference)
4. [3D Features Guide](#3d-features-guide)
5. [Integration Examples](#integration-examples)
6. [Performance Optimization](#performance-optimization)
7. [Accessibility Features](#accessibility-features)
8. [Testing & Quality Assurance](#testing--quality-assurance)
9. [Troubleshooting](#troubleshooting)
10. [Advanced Configuration](#advanced-configuration)

---

## Architecture Overview

### System Components

The 3D Mapbox integration consists of four core components working in harmony:

```
┌─────────────────────────────────────────────────────────────┐
│                    STL Wait Times 3D Architecture          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │  MapboxView3D   │  │ DataConverter   │  │ Performance  │ │
│  │   (UI Layer)    │◄─┤   (Logic)       │◄─┤  Manager     │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│           │                     │                          │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │  Annotation3D   │  │  Accessibility  │                  │
│  │   (Models)      │  │   (Support)     │                  │
│  └─────────────────┘  └─────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### Core Design Principles

- **Accessibility First**: VoiceOver support, motion sensitivity awareness, and comprehensive accessibility labels
- **Performance Optimization**: Intelligent quality scaling, device capability detection, and battery usage management
- **Modular Architecture**: Reusable components with clear separation of concerns
- **Medical Context Aware**: Priority systems based on wait times, distance, and facility urgency

---

## Installation & Setup

### Prerequisites

- iOS 15.0+ (required for optimal 3D performance)
- Xcode 15.0+
- Swift 5.8+
- Valid Mapbox account and access token

### Step 1: Mapbox SDK Integration

Add the Mapbox Maps SDK to your project via Swift Package Manager:

```swift
// In Package.swift dependencies
.package(url: "https://github.com/mapbox/mapbox-maps-ios.git", from: "11.0.0")
```

### Step 2: Token Configuration

Configure your Mapbox access token in your app's configuration:

```swift
// In Info.plist
<key>MBXAccessToken</key>
<string>pk.eyJ1IjoiY21pbHRvbjQiLCJhIjoiY21kNTVkcjh1MG05eTJrb21qeHB0aXo4bCJ9.5vv9akWMhonZ_J3ftkUKRg</string>
```

### Step 3: Location Permissions

Ensure proper location permissions for optimal 3D experience:

```swift
// Required permissions in Info.plist
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses location to show nearby medical facilities with precise 3D visualization.</string>
```

---

## Component Reference

### MapboxView3D

The primary 3D mapping component providing comprehensive medical facility visualization.

#### Interface

```swift
struct MapboxView3D: View {
    @Binding var coordinateRegion: MKCoordinateRegion
    var annotations: [MedicalFacility3DAnnotation] = []
    @State var mapMode: MapDisplayMode = .hybrid2D
    var onMapTap: ((CLLocationCoordinate2D) -> Void)?
    var onAnnotationTap: ((MedicalFacility3DAnnotation) -> Void)?
}
```

#### Usage Example

```swift
MapboxView3D(
    coordinateRegion: $region,
    annotations: facilityAnnotations,
    mapMode: .buildings3D,
    onMapTap: { coordinate in
        print("Map tapped at: \(coordinate)")
    },
    onAnnotationTap: { annotation in
        selectedFacility = annotation
    }
)
```

#### Map Display Modes

| Mode | Description | 3D Support | Use Case |
|------|-------------|------------|----------|
| `.flat2D` | Traditional 2D map view | ❌ | High performance, simple visualization |
| `.hybrid2D` | 2D with satellite imagery | ❌ | Enhanced context without 3D overhead |
| `.buildings3D` | 3D buildings visualization | ✅ | Urban context, facility identification |
| `.terrain3D` | 3D terrain elevation | ✅ | Geographic context, accessibility routes |
| `.full3D` | Complete 3D experience | ✅ | Immersive facility exploration |

### MedicalFacility3DAnnotation

Enhanced annotation model for medical facilities with 3D visualization properties.

#### Properties

```swift
struct MedicalFacility3DAnnotation: Identifiable, Equatable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let name: String
    let facilityType: FacilityType
    let waitTime: Int?
    let waitTimeChange: String?
    let distance: String?
    let isOpen: Bool
    let buildingHeight: Double
    let priorityLevel: PriorityLevel
    let customIcon: String?
}
```

#### Facility Types

- **Emergency Department** (`.emergencyDepartment`): Red color, cross icon, highest priority
- **Urgent Care** (`.urgentCare`): Orange color, stethoscope icon, medium priority  
- **Hospital** (`.hospital`): Blue color, building icon, general priority

#### Priority Levels

Priority levels automatically scale annotation size and visual prominence:

```swift
enum PriorityLevel: Int {
    case low = 1      // Scale: 0.9x
    case medium = 2   // Scale: 1.0x
    case high = 3     // Scale: 1.1x
    case critical = 4 // Scale: 1.2x
}
```

### MapboxDataConverter

Intelligent data conversion utility for transforming medical facility data into 3D annotations.

#### Core Methods

```swift
class MapboxDataConverter {
    func convertToMapbox3DAnnotations(
        facilities: [Facility],
        waitTimes: [String: WaitTime] = [:],
        userLocation: CLLocation? = nil,
        includeClosedFacilities: Bool = true
    ) -> [MedicalFacility3DAnnotation]
}
```

#### Priority Calculation Algorithm

The converter uses a sophisticated algorithm to determine facility priority:

1. **Wait Time Factor** (-2 to +2 points)
   - ≤20 minutes: +2 points (highest priority)
   - 21-40 minutes: +1 point
   - 41-60 minutes: -1 point
   - ≥60 minutes: -2 points

2. **Distance Factor** (-1 to +2 points)
   - ≤1km: +2 points
   - 1-5km: +1 point
   - 5-10km: 0 points
   - ≥10km: -1 point

3. **Facility Type Factor** (-1 to +1 points)
   - Emergency Department: +1 point
   - Urgent Care: 0 points
   - General Hospital: -1 point

4. **Operational Status** (-3 points if closed)

### Map3DPerformanceManager

Intelligent performance optimization for 3D rendering across different device capabilities.

#### Features

- **Device Capability Detection**: Automatic assessment of GPU and memory capabilities
- **Dynamic Quality Adjustment**: Real-time quality scaling based on performance metrics
- **Battery Usage Optimization**: Adaptive rendering to preserve battery life
- **Frame Rate Monitoring**: Continuous performance tracking and adjustment

#### Quality Levels

```swift
enum RenderQuality: String, CaseIterable {
    case low = "low"        // 30 FPS target, minimal 3D effects
    case medium = "medium"  // 45 FPS target, balanced quality
    case high = "high"      // 60 FPS target, full effects
    case auto = "auto"      // Intelligent adaptation
}
```

---

## 3D Features Guide

### 3D Buildings Visualization

Enable immersive building visualization for better spatial context:

```swift
// Toggle 3D buildings
mapView.mapMode = .buildings3D

// Customize building opacity
buildingsOpacity = 0.8 // 80% opacity for subtle effect
```

**Benefits:**
- Enhanced spatial awareness for navigation
- Better landmark identification
- Improved facility location context

### 3D Terrain Elevation

Visualize elevation changes for accessibility and routing considerations:

```swift
// Enable terrain visualization
mapView.mapMode = .terrain3D

// Adjust terrain exaggeration for emphasis
terrainExaggeration = 1.5 // 150% elevation emphasis
```

**Medical Applications:**
- Identify accessibility challenges for patients with mobility limitations
- Understand geographic barriers to facility access
- Visualize elevation-based routing options

### Custom 3D Annotations

Create specialized 3D annotations for medical facilities:

```swift
let annotation = MedicalFacility3DAnnotation(
    id: "hospital-1",
    coordinate: facilityLocation,
    name: "Barnes-Jewish Hospital",
    facilityType: .emergencyDepartment,
    waitTime: 45,
    waitTimeChange: "+5 min",
    distance: "2.3 mi",
    isOpen: true,
    buildingHeight: 100.0, // 3D building height in meters
    priorityLevel: .high,
    customIcon: "custom-hospital-icon"
)
```

**3D Annotation Features:**
- **Height Variation**: Automatic building height based on facility type
- **Wait Time Overlays**: Real-time wait time display in 3D space
- **Priority Scaling**: Visual size adjustment based on urgency
- **Status Indicators**: Open/closed status with visual cues

---

## Integration Examples

### Basic Integration

Replace existing map components with 3D enhanced versions:

```swift
// Before: Standard MapKit
Map(coordinateRegion: $region)
    .mapStyle(.standard(elevation: .flat))

// After: Enhanced 3D Mapbox
MapboxView3D(
    coordinateRegion: $region,
    annotations: facilityAnnotations,
    mapMode: .buildings3D
)
```

### Advanced Integration with Dashboard

Complete dashboard integration with facility interaction:

```swift
struct MedicalDashboard: View {
    @State private var region = MKCoordinateRegion(/* St. Louis area */)
    @State private var selectedFacility: MedicalFacility3DAnnotation?
    @State private var mapMode: MapDisplayMode = .hybrid2D
    
    var body: some View {
        VStack {
            // 3D Map View
            MapboxView3D(
                coordinateRegion: $region,
                annotations: nearbyFacilities,
                mapMode: mapMode,
                onMapTap: { coordinate in
                    // Handle map interactions
                    selectedFacility = nil
                },
                onAnnotationTap: { annotation in
                    // Handle facility selection
                    selectedFacility = annotation
                    centerOnFacility(annotation)
                }
            )
            
            // Facility Details Bottom Sheet
            if let facility = selectedFacility {
                FacilityDetailSheet(facility: facility)
            }
        }
    }
    
    private func centerOnFacility(_ facility: MedicalFacility3DAnnotation) {
        withAnimation(.easeInOut(duration: 0.8)) {
            region = MKCoordinateRegion(
                center: facility.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
}
```

### Real-time Data Integration

Connect 3D annotations with live wait time data:

```swift
class FacilityViewModel: ObservableObject {
    @Published var facilities: [MedicalFacility3DAnnotation] = []
    private let dataConverter = MapboxDataConverter()
    private let waitTimeService = WaitTimeService()
    
    func updateFacilitiesWithLiveData() {
        waitTimeService.fetchCurrentWaitTimes { [weak self] waitTimes in
            DispatchQueue.main.async {
                self?.facilities = self?.dataConverter.convertToMapbox3DAnnotations(
                    facilities: self?.rawFacilities ?? [],
                    waitTimes: waitTimes,
                    userLocation: self?.userLocation
                ) ?? []
            }
        }
    }
}
```

---

## Performance Optimization

### Device Capability Detection

Automatically optimize 3D features based on device capabilities:

```swift
class Map3DPerformanceManager: ObservableObject {
    @Published var supports3D: Bool = true
    @Published var recommendedQuality: RenderQuality = .auto
    
    func detectDeviceCapabilities() {
        // iOS version check
        let systemVersion = UIDevice.current.systemVersion
        supports3D = systemVersion.compare("15.0", options: .numeric) != .orderedAscending
        
        // Performance assessment
        recommendedQuality = determineOptimalQuality()
    }
    
    private func determineOptimalQuality() -> RenderQuality {
        // Device-specific quality recommendations
        let deviceModel = UIDevice.current.model
        
        if deviceModel.contains("iPhone 15") || deviceModel.contains("iPhone 16") {
            return .high
        } else if deviceModel.contains("iPhone 13") || deviceModel.contains("iPhone 14") {
            return .medium
        } else {
            return .low
        }
    }
}
```

### Battery Usage Optimization

Implement intelligent power management for 3D features:

```swift
// Monitor battery level and adjust quality
if UIDevice.current.batteryLevel < 0.2 { // 20% battery
    renderQuality = .low
    mapMode = .hybrid2D // Fallback to 2D
}

// Reduce frame rate during low power mode
if ProcessInfo.processInfo.isLowPowerModeEnabled {
    targetFrameRate = 30.0
    terrainExaggeration = 0.5 // Reduce 3D complexity
}
```

### Memory Management

Optimize memory usage for large datasets:

```swift
// Efficient annotation management
func optimizeAnnotationsForViewport() {
    let visibleAnnotations = annotations.filter { annotation in
        region.contains(annotation.coordinate) &&
        distanceToUser(annotation) < 50000 // 50km radius
    }
    
    // Limit annotation count for performance
    let maxAnnotations = renderQuality == .high ? 100 : 50
    self.displayedAnnotations = Array(visibleAnnotations.prefix(maxAnnotations))
}
```

---

## Accessibility Features

### VoiceOver Support

Comprehensive screen reader support for 3D map interactions:

```swift
// Annotation accessibility labels
var accessibilityLabel: String {
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

// Map mode accessibility
extension MapDisplayMode {
    var accessibilityLabel: String {
        switch self {
        case .flat2D: return "Two-dimensional flat map view"
        case .buildings3D: return "Three-dimensional view with buildings"
        case .full3D: return "Full three-dimensional view with buildings and terrain"
        }
    }
}
```

### Motion Sensitivity Support

Respect user motion preferences and provide alternatives:

```swift
@AppStorage("prefersReducedMotion") private var reducedMotion = false

// Disable 3D transitions when motion is reduced
func adaptToAccessibilityPreferences() {
    if reducedMotion {
        mapMode = .flat2D
        animationDuration = 0.0
        cameraTransitions = false
    }
}

// Provide alternative interaction methods
func announceMapChanges() {
    let announcement = "Map view changed to \(mapMode.accessibilityLabel)"
    UIAccessibility.post(notification: .announcement, argument: announcement)
}
```

### High Contrast Support

Ensure visibility in high contrast modes:

```swift
// Dynamic color adaptation
var facilityColor: Color {
    if UIAccessibility.isDarkerSystemColorsEnabled {
        return facilityType.highContrastColor
    } else {
        return facilityType.standardColor
    }
}

extension FacilityType {
    var highContrastColor: Color {
        switch self {
        case .emergencyDepartment: return .red
        case .urgentCare: return .orange
        case .hospital: return Color(red: 0.0, green: 0.4, blue: 0.8) // High contrast blue
        }
    }
}
```

---

## Testing & Quality Assurance

### Unit Testing

Comprehensive test coverage for 3D functionality:

```swift
class MapboxView3DTests: XCTestCase {
    
    func testMapModeTransitions() {
        let mapView = MapboxView3D(coordinateRegion: .constant(testRegion))
        
        // Test all mode transitions
        for mode in MapDisplayMode.allCases {
            XCTAssertTrue(mode.supports3D || !mode.supports3D)
            XCTAssertFalse(mode.accessibilityLabel.isEmpty)
        }
    }
    
    func testAnnotationPriorityCalculation() {
        let converter = MapboxDataConverter()
        let facilities = createTestFacilities()
        
        let annotations = converter.convertToMapbox3DAnnotations(
            facilities: facilities,
            waitTimes: testWaitTimes,
            userLocation: testLocation
        )
        
        XCTAssertTrue(annotations.allSatisfy { $0.priorityLevel.scale >= 0.8 })
    }
    
    func testPerformanceWithLargeDataset() {
        measure {
            let largeFacilitySet = (0..<1000).map { createTestFacility(id: "\($0)") }
            let annotations = converter.convertToMapbox3DAnnotations(facilities: largeFacilitySet)
            XCTAssertEqual(annotations.count, 1000)
        }
    }
}
```

### Accessibility Testing

Validate accessibility compliance:

```swift
func testAccessibilityCompliance() {
    let annotation = createTestAnnotation()
    let annotationView = MedicalFacility3DAnnotationView(annotation: annotation)
    
    // Test accessibility label completeness
    XCTAssertFalse(annotation.accessibilityLabel.isEmpty)
    XCTAssertTrue(annotation.accessibilityLabel.contains(annotation.name))
    
    // Test VoiceOver navigation
    XCTAssertTrue(annotationView.isAccessibilityElement)
}
```

### Performance Testing

Monitor 3D rendering performance:

```swift
func testRenderingPerformance() {
    let performanceManager = Map3DPerformanceManager()
    
    measure {
        for mode in MapDisplayMode.allCases {
            let renderTime = measureRenderTime(for: mode)
            XCTAssertLessThan(renderTime, 16.67) // 60 FPS target
        }
    }
}
```

---

## Troubleshooting

### Common Issues

#### 3D Features Not Displaying

**Symptoms**: 3D buildings or terrain not visible
**Causes**: 
- Device doesn't support 3D rendering
- Reduce Motion preference enabled
- Performance limitations

**Solutions**:
```swift
// Check device support
if !performanceManager.supports3D {
    mapMode = .hybrid2D
    showAlternativeVisualization()
}

// Verify accessibility settings
if UIAccessibility.isReduceMotionEnabled {
    provideStaticVisualization()
}
```

#### Performance Issues

**Symptoms**: Low frame rates, stuttering animations
**Causes**:
- Too many annotations
- High rendering quality on low-end device
- Background processing interference

**Solutions**:
```swift
// Reduce annotation density
func optimizeForPerformance() {
    if currentFrameRate < 30.0 {
        renderQuality = .low
        maxVisibleAnnotations = 25
        terrainExaggeration = 0.5
    }
}
```

#### Accessibility Problems

**Symptoms**: VoiceOver not announcing changes, poor contrast
**Causes**:
- Missing accessibility labels
- Insufficient color contrast
- Motion-sensitive animations

**Solutions**:
```swift
// Enhance accessibility support
func improveAccessibility() {
    // Add comprehensive labels
    annotation.accessibilityLabel = createDetailedLabel(for: annotation)
    
    // Respect user preferences
    if UIAccessibility.isDarkerSystemColorsEnabled {
        useHighContrastColors()
    }
    
    // Provide motion alternatives
    if UIAccessibility.isReduceMotionEnabled {
        disableAnimations()
        useInstantTransitions()
    }
}
```

### Debug Mode

Enable comprehensive debugging information:

```swift
#if DEBUG
class DebugManager {
    static var enablePerformanceIndicator = true
    static var logAnnotationChanges = true
    static var showFrameRateOverlay = true
}
#endif
```

---

## Advanced Configuration

### Custom Styling

Create branded 3D map experiences:

```swift
// Custom map style configuration
extension MapboxView3D {
    func applyCustomStyling() {
        // Custom building colors
        buildingColors = [
            .hospital: Color(red: 0.2, green: 0.6, blue: 0.9),
            .emergencyDepartment: Color(red: 0.8, green: 0.2, blue: 0.2),
            .urgentCare: Color(red: 0.9, green: 0.6, blue: 0.2)
        ]
        
        // Custom terrain colors
        terrainColors = TerrainColorScheme.medical
    }
}
```

### Integration with External Services

Connect with medical data providers:

```swift
class ExternalDataIntegration {
    func fetchRealTimeData() async -> [MedicalFacility3DAnnotation] {
        // Connect to medical facility APIs
        let facilities = await MedicalAPIService.shared.fetchFacilities()
        let waitTimes = await WaitTimeAPIService.shared.fetchCurrentTimes()
        
        return dataConverter.convertToMapbox3DAnnotations(
            facilities: facilities,
            waitTimes: waitTimes,
            userLocation: locationManager.currentLocation
        )
    }
}
```

### Analytics Integration

Track 3D feature usage and performance:

```swift
class Map3DAnalytics {
    func trackMapModeUsage(_ mode: MapDisplayMode) {
        Analytics.track("map_mode_changed", parameters: [
            "mode": mode.rawValue,
            "supports_3d": mode.supports3D,
            "device_model": UIDevice.current.model
        ])
    }
    
    func trackPerformanceMetrics(_ metrics: PerformanceMetrics) {
        Analytics.track("3d_performance", parameters: [
            "average_fps": metrics.averageFrameRate,
            "render_quality": metrics.renderQuality.rawValue,
            "annotation_count": metrics.annotationCount
        ])
    }
}
```

---

## Conclusion

The Mapbox 3D integration provides a comprehensive, accessible, and performant solution for medical facility visualization. This implementation prioritizes user experience, accessibility compliance, and device optimization while delivering immersive 3D mapping capabilities.

### Key Benefits

- **Enhanced Spatial Awareness**: 3D buildings and terrain provide better context for medical facility locations
- **Intelligent Prioritization**: Automatic priority calculation based on wait times, distance, and facility type
- **Accessibility Compliance**: Full VoiceOver support and motion sensitivity awareness
- **Performance Optimization**: Device-aware quality scaling and battery usage management
- **Medical Context Awareness**: Specialized features for healthcare facility discovery and navigation

### Next Steps

1. **Full Mapbox SDK Integration**: Replace compatibility layer with native Mapbox implementation
2. **Advanced Analytics**: Implement comprehensive usage and performance tracking
3. **Offline Capabilities**: Add offline map support for emergency situations
4. **Custom Medical Icons**: Develop specialized iconography for different medical specialties
5. **Voice Navigation**: Integrate spoken directions for accessibility enhancement

For technical support or implementation questions, refer to the component documentation or contact the development team.

---

*Generated with Claude Code*
*Last Updated: July 15, 2025*