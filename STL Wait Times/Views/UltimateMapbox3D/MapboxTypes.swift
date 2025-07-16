//
//  MapboxTypes.swift
//  STL Wait Times
//
//  Supporting types and enums for Ultimate 3D Mapbox component
//  Created by SuperClaude Enterprise Framework on 7/16/25.
//

import Foundation
import CoreLocation
import SwiftUI
import MapKit

// MARK: - Rendering Quality & LOD

/// **RenderingQuality**: Comprehensive quality levels for 3D rendering
enum RenderingQuality: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case ultra = "ultra"
    case debug = "debug"
    
    var displayName: String {
        switch self {
        case .low: return "Low Quality"
        case .medium: return "Medium Quality"
        case .high: return "High Quality"
        case .ultra: return "Ultra Quality"
        case .debug: return "Debug Mode"
        }
    }
    
    var targetFrameRate: Double {
        switch self {
        case .low: return 30.0
        case .medium: return 45.0
        case .high: return 60.0
        case .ultra: return 60.0
        case .debug: return 15.0
        }
    }
}

/// **LODConfiguration**: Level of Detail settings for 3D models
struct LODConfiguration: Equatable {
    let maxDistance: Double
    let qualityLevels: Int
    let transitionZones: [Double]
    let cullingDistance: Double
    
    static let balanced = LODConfiguration(
        maxDistance: 10000.0,
        qualityLevels: 3,
        transitionZones: [1000.0, 5000.0, 10000.0],
        cullingDistance: 15000.0
    )
    
    static let highDetail = LODConfiguration(
        maxDistance: 20000.0,
        qualityLevels: 5,
        transitionZones: [500.0, 2000.0, 5000.0, 10000.0, 20000.0],
        cullingDistance: 25000.0
    )
    
    static let medicalFacilities = LODConfiguration(
        maxDistance: 5000.0,
        qualityLevels: 3,
        transitionZones: [500.0, 2000.0, 5000.0],
        cullingDistance: 8000.0
    )
    
    static let debug = LODConfiguration(
        maxDistance: 1000.0,
        qualityLevels: 1,
        transitionZones: [1000.0],
        cullingDistance: 1500.0
    )
}

/// **TextureConfiguration**: Texture quality and compression settings
struct TextureConfiguration: Equatable {
    let compressionLevel: Double
    let maxTextureSize: Int
    let mipmapLevels: Int
    let anisotropicFiltering: Int
    
    static let balanced = TextureConfiguration(
        compressionLevel: 0.7,
        maxTextureSize: 1024,
        mipmapLevels: 4,
        anisotropicFiltering: 4
    )
    
    static let highQuality = TextureConfiguration(
        compressionLevel: 0.9,
        maxTextureSize: 2048,
        mipmapLevels: 6,
        anisotropicFiltering: 8
    )
    
    static let medical = TextureConfiguration(
        compressionLevel: 0.8,
        maxTextureSize: 1024,
        mipmapLevels: 4,
        anisotropicFiltering: 4
    )
    
    static let debug = TextureConfiguration(
        compressionLevel: 1.0,
        maxTextureSize: 512,
        mipmapLevels: 1,
        anisotropicFiltering: 1
    )
}

// MARK: - Performance Optimization

/// **LODStrategy**: Level of detail optimization strategies
enum LODStrategy: String, CaseIterable {
    case staticLevel = "static"
    case adaptive = "adaptive"
    case realTime = "realTime"
    case enterprise = "enterprise"
    case debug = "debug"
}

/// **TextureCompressionStrategy**: Texture optimization strategies
enum TextureCompressionStrategy: String, CaseIterable {
    case none = "none"
    case fast = "fast"
    case balanced = "balanced"
    case highQuality = "highQuality"
}

/// **CullingStrategy**: Object culling optimization strategies
enum CullingStrategy: String, CaseIterable {
    case none = "none"
    case frustum = "frustum"
    case occlusion = "occlusion"
    case aggressive = "aggressive"
}

/// **RenderPipelineOptimization**: Rendering pipeline optimization levels
enum RenderPipelineOptimization: String, CaseIterable {
    case debug = "debug"
    case standard = "standard"
    case realTime = "realTime"
    case maximum = "maximum"
}

// MARK: - UI Configuration

/// **UITheme**: User interface theme options
enum UITheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
    case highContrast = "highContrast"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil
        case .highContrast: return .dark
        }
    }
}

/// **UIControlSize**: Control size options for accessibility
enum UIControlSize: String, CaseIterable {
    case compact = "compact"
    case standard = "standard"
    case large = "large"
    
    var buttonSize: CGFloat {
        switch self {
        case .compact: return 32.0
        case .standard: return 44.0
        case .large: return 56.0
        }
    }
}

/// **UIShadowConfiguration**: Shadow settings for UI elements
struct UIShadowConfiguration: Equatable {
    let radius: CGFloat
    let opacity: Double
    let offset: CGSize
    let color: Color
    
    static let standard = UIShadowConfiguration(
        radius: 4.0,
        opacity: 0.2,
        offset: CGSize(width: 0, height: 2),
        color: .black
    )
    
    static let professional = UIShadowConfiguration(
        radius: 2.0,
        opacity: 0.15,
        offset: CGSize(width: 0, height: 1),
        color: .black
    )
    
    static let accessibility = UIShadowConfiguration(
        radius: 6.0,
        opacity: 0.3,
        offset: CGSize(width: 0, height: 3),
        color: .black
    )
    
    static let debug = UIShadowConfiguration(
        radius: 1.0,
        opacity: 0.5,
        offset: CGSize(width: 0, height: 1),
        color: .red
    )
}

// MARK: - Missing Type Definitions

/// **MedicalFacility3DAnnotation**: 3D medical facility annotation
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
    
    enum FacilityType {
        case emergencyDepartment
        case urgentCare
        case hospital
        case clinic
        case pharmacy
    }
    
    enum PriorityLevel {
        case low
        case medium
        case high
        case critical
    }
    
    static func == (lhs: MedicalFacility3DAnnotation, rhs: MedicalFacility3DAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

// PerformanceMetrics is defined in MapboxCore3DEngine.swift

// PerformanceConfiguration and ExtensibilityConfiguration are defined in MapboxConfiguration.swift

// RenderingConfiguration is defined in MapboxConfiguration.swift

// MARK: - Extensibility

/// **PluginType**: Available plugin types for extensibility
enum PluginType: String, CaseIterable {
    case mapGPT = "mapGPT"
    case voiceAI = "voiceAI"
    case gpxOverlay = "gpxOverlay"
    case indoorNavigation = "indoorNavigation"
    case collaboration = "collaboration"
    case arVr = "arVr"
    case analytics = "analytics"
    case customRenderer = "customRenderer"
}

/// **APIVersioningStrategy**: API versioning and compatibility strategies
enum APIVersioningStrategy: String, CaseIterable {
    case stable = "stable"
    case progressive = "progressive"
    case experimental = "experimental"
}

// MARK: - Camera System

/// **MapboxCameraState**: Comprehensive camera state and positioning
struct MapboxCameraState: Equatable {
    let center: CLLocationCoordinate2D
    let zoom: Double
    let pitch: Double
    let bearing: Double
    let altitude: Double
    let is3D: Bool
    
    static func == (lhs: MapboxCameraState, rhs: MapboxCameraState) -> Bool {
        return lhs.center.latitude == rhs.center.latitude &&
               lhs.center.longitude == rhs.center.longitude &&
               lhs.zoom == rhs.zoom &&
               lhs.pitch == rhs.pitch &&
               lhs.bearing == rhs.bearing &&
               lhs.altitude == rhs.altitude &&
               lhs.is3D == rhs.is3D
    }
    
    init(
        center: CLLocationCoordinate2D,
        zoom: Double = 12.0,
        pitch: Double = 0.0,
        bearing: Double = 0.0,
        altitude: Double = 1000.0,
        is3D: Bool = false
    ) {
        self.center = center
        self.zoom = zoom
        self.pitch = pitch
        self.bearing = bearing
        self.altitude = altitude
        self.is3D = is3D
    }
    
    /// Default camera state
    static let `default` = MapboxCameraState(
        center: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
        zoom: 12.0
    )
    
    /// St. Louis 3D view optimized for medical facilities
    static let stLouis3D = MapboxCameraState(
        center: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
        zoom: 13.0,
        pitch: 45.0,
        bearing: 0.0,
        altitude: 1500.0,
        is3D: true
    )
    
    /// Convert to MKCoordinateRegion for MapKit compatibility
    var mapKitRegion: MKCoordinateRegion {
        let span = MKCoordinateSpan(
            latitudeDelta: 0.1 / zoom,
            longitudeDelta: 0.1 / zoom
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Map Styles

/// **MapboxStyle**: Advanced map styling options
enum MapboxStyle: String, CaseIterable, Identifiable {
    case standard = "standard"
    case satellite = "satellite"
    case dark = "dark"
    case light = "light"
    case outdoors = "outdoors"
    case medicalCustom = "medicalCustom"
    case navigation = "navigation"
    case traffic = "traffic"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .satellite: return "Satellite"
        case .dark: return "Dark"
        case .light: return "Light"
        case .outdoors: return "Outdoors"
        case .medicalCustom: return "Medical"
        case .navigation: return "Navigation"
        case .traffic: return "Traffic"
        }
    }
    
    var iconName: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe.americas"
        case .dark: return "moon"
        case .light: return "sun.max"
        case .outdoors: return "mountain.2"
        case .medicalCustom: return "cross.circle"
        case .navigation: return "location"
        case .traffic: return "car"
        }
    }
    
    var accessibilityDescription: String {
        switch self {
        case .standard: return "Standard map style with balanced detail"
        case .satellite: return "Satellite imagery with geographic context"
        case .dark: return "Dark theme optimized for low-light viewing"
        case .light: return "Light theme with high contrast"
        case .outdoors: return "Outdoor terrain and elevation emphasis"
        case .medicalCustom: return "Medical facility optimized styling"
        case .navigation: return "Navigation optimized with route emphasis"
        case .traffic: return "Real-time traffic condition visualization"
        }
    }
    
    var supports3D: Bool {
        switch self {
        case .standard, .satellite, .dark, .outdoors, .medicalCustom, .navigation:
            return true
        case .light, .traffic:
            return false
        }
    }
    
    var mapKitEquivalent: MKMapType {
        switch self {
        case .standard, .medicalCustom, .navigation, .dark, .light:
            return .standard
        case .satellite, .outdoors:
            return .hybrid
        case .traffic:
            return .standard
        }
    }
    
    /// Default styles for most use cases
    static let defaultStyles: [MapboxStyle] = [.standard, .satellite, .dark]
    
    /// All available styles
    static let allCases: [MapboxStyle] = [
        .standard, .satellite, .dark, .light, .outdoors, .medicalCustom, .navigation, .traffic
    ]
}

// MARK: - Advanced Annotations

/// **AdvancedMapAnnotation**: Enterprise-grade map annotation with 3D capabilities
struct AdvancedMapAnnotation: Identifiable, Equatable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String?
    let annotationType: AnnotationType
    let visualStyle: AnnotationVisualStyle
    let interactionData: AnnotationInteractionData
    let accessibility: AnnotationAccessibility
    let renderingOptions: AnnotationRenderingOptions
    
    enum AnnotationType {
        case medicalFacility(MedicalFacilityData)
        case customLocation(CustomLocationData)
        case route(RouteData)
        case area(AreaData)
        case poi(POIData)
    }
    
    struct MedicalFacilityData {
        let facilityType: MedicalFacilityType
        let waitTime: Int?
        let isOpen: Bool
        let services: [String]
        let priority: MedicalFacilityPriority
    }
    
    enum MedicalFacilityPriority {
        case low, medium, high, critical
    }
    
    enum MedicalFacilityType {
        case emergencyDepartment
        case urgentCare
        case hospital
        case clinic
        case pharmacy
        case laboratoryDiagnostics
    }
    
    struct CustomLocationData {
        let category: String
        let metadata: [String: Any]
    }
    
    struct RouteData {
        let routeType: RouteType
        let waypoints: [CLLocationCoordinate2D]
        let estimatedTime: TimeInterval
    }
    
    enum RouteType {
        case driving
        case walking
        case transit
        case emergency
    }
    
    struct AreaData {
        let polygon: [CLLocationCoordinate2D]
        let areaType: AreaType
        let extrusionHeight: Double?
    }
    
    enum AreaType {
        case building
        case facility
        case zone
        case floorplan
    }
    
    struct POIData {
        let category: String
        let rating: Double?
        let reviews: Int?
    }
    
    static func == (lhs: AdvancedMapAnnotation, rhs: AdvancedMapAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Annotation Configuration

/// **AnnotationVisualStyle**: Visual styling for annotations
struct AnnotationVisualStyle {
    let color: Color
    let size: AnnotationSize
    let icon: String
    let customIcon: UIImage?
    let animationEnabled: Bool
    let glowEffect: Bool
    let shadowConfiguration: UIShadowConfiguration
    
    enum AnnotationSize {
        case small, medium, large, adaptive
        
        var baseSize: CGFloat {
            switch self {
            case .small: return 24.0
            case .medium: return 32.0
            case .large: return 44.0
            case .adaptive: return 32.0
            }
        }
    }
}

/// **AnnotationInteractionData**: Interaction behavior for annotations
struct AnnotationInteractionData {
    let tapAction: AnnotationTapAction?
    let hoverEnabled: Bool
    let selectionEnabled: Bool
    let dragEnabled: Bool
    let customData: [String: Any]
    
    enum AnnotationTapAction {
        case showDetails
        case navigate
        case call
        case custom(String)
    }
}

/// **AnnotationAccessibility**: Accessibility configuration for annotations
struct AnnotationAccessibility {
    let accessibilityLabel: String
    let accessibilityHint: String?
    let accessibilityValue: String?
    let voiceOverPriority: VoiceOverPriority
    
    enum VoiceOverPriority {
        case low, medium, high, critical
    }
}

/// **AnnotationRenderingOptions**: 3D rendering options for annotations
struct AnnotationRenderingOptions {
    let enable3D: Bool
    let extrusionHeight: Double
    let lightingEnabled: Bool
    let shadowsEnabled: Bool
    let lodLevel: Int
    let cullingEnabled: Bool
}

// MARK: - Sample Data

extension AdvancedMapAnnotation {
    /// Sample medical facility annotations for testing
    static func sampleMedicalFacilities() -> [AdvancedMapAnnotation] {
        return [
            AdvancedMapAnnotation(
                id: "barnes-jewish",
                coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
                title: "Barnes-Jewish Hospital",
                subtitle: "Emergency Department",
                annotationType: .medicalFacility(MedicalFacilityData(
                    facilityType: .emergencyDepartment,
                    waitTime: 45,
                    isOpen: true,
                    services: ["Emergency Care", "Trauma Center", "Cardiology"],
                    priority: .critical
                )),
                visualStyle: AnnotationVisualStyle(
                    color: .red,
                    size: .large,
                    icon: "cross.circle.fill",
                    customIcon: nil,
                    animationEnabled: true,
                    glowEffect: true,
                    shadowConfiguration: .standard
                ),
                interactionData: AnnotationInteractionData(
                    tapAction: .showDetails,
                    hoverEnabled: true,
                    selectionEnabled: true,
                    dragEnabled: false,
                    customData: [:]
                ),
                accessibility: AnnotationAccessibility(
                    accessibilityLabel: "Barnes-Jewish Hospital Emergency Department",
                    accessibilityHint: "45 minute wait time, currently open",
                    accessibilityValue: "Emergency Department",
                    voiceOverPriority: .high
                ),
                renderingOptions: AnnotationRenderingOptions(
                    enable3D: true,
                    extrusionHeight: 100.0,
                    lightingEnabled: true,
                    shadowsEnabled: true,
                    lodLevel: 3,
                    cullingEnabled: true
                )
            ),
            
            AdvancedMapAnnotation(
                id: "urgent-care-plus",
                coordinate: CLLocationCoordinate2D(latitude: 38.6370, longitude: -90.2094),
                title: "Urgent Care Plus",
                subtitle: "Urgent Care Center",
                annotationType: .medicalFacility(MedicalFacilityData(
                    facilityType: .urgentCare,
                    waitTime: 15,
                    isOpen: true,
                    services: ["Urgent Care", "X-Ray", "Lab Services"],
                    priority: .high
                )),
                visualStyle: AnnotationVisualStyle(
                    color: .orange,
                    size: .medium,
                    icon: "stethoscope.circle.fill",
                    customIcon: nil,
                    animationEnabled: true,
                    glowEffect: false,
                    shadowConfiguration: .standard
                ),
                interactionData: AnnotationInteractionData(
                    tapAction: .showDetails,
                    hoverEnabled: true,
                    selectionEnabled: true,
                    dragEnabled: false,
                    customData: [:]
                ),
                accessibility: AnnotationAccessibility(
                    accessibilityLabel: "Urgent Care Plus",
                    accessibilityHint: "15 minute wait time, currently open",
                    accessibilityValue: "Urgent Care Center",
                    voiceOverPriority: .medium
                ),
                renderingOptions: AnnotationRenderingOptions(
                    enable3D: true,
                    extrusionHeight: 25.0,
                    lightingEnabled: true,
                    shadowsEnabled: true,
                    lodLevel: 2,
                    cullingEnabled: true
                )
            )
        ]
    }
}