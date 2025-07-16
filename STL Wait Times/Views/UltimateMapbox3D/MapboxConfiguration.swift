//
//  MapboxConfiguration.swift
//  STL Wait Times
//
//  Enterprise configuration system for Ultimate 3D Mapbox component
//  Created by SuperClaude Enterprise Framework on 7/16/25.
//

import Foundation
import CoreLocation
import SwiftUI

/// **MapboxConfiguration**: Comprehensive configuration system for enterprise 3D mapping
///
/// **Design Principles:**
/// - 🏗️ Modular configuration with clear separation of concerns
/// - ⚡ Performance-first with intelligent defaults
/// - 🔧 Extensible for future features and customization
/// - ♿ Accessibility-aware configuration options
/// - 📊 Analytics and monitoring integration ready
///
/// **Usage:**
/// ```swift
/// let config = MapboxConfiguration(
///     renderingConfiguration: .highPerformance,
///     uiConfiguration: .professional,
///     performanceConfiguration: .enterprise
/// )
/// ```
struct MapboxConfiguration: Equatable {
    
    // MARK: - Core Configuration Components
    
    /// 3D rendering engine configuration
    let renderingConfiguration: RenderingConfiguration
    
    /// User interface controls configuration
    let uiConfiguration: UIConfiguration
    
    /// Performance monitoring and optimization settings
    let performanceConfiguration: PerformanceConfiguration
    
    /// Extensibility and future features configuration
    let extensibilityConfiguration: ExtensibilityConfiguration
    
    /// Initial camera positioning and state
    let initialCameraState: MapboxCameraState
    
    /// Available map styles for user selection
    let availableStyles: [MapboxStyle]
    
    /// Development and debugging options
    let developmentConfiguration: DevelopmentConfiguration
    
    // MARK: - Initializers
    
    /// Initialize with custom configuration components
    init(
        renderingConfiguration: RenderingConfiguration = .balanced,
        uiConfiguration: UIConfiguration = .standard,
        performanceConfiguration: PerformanceConfiguration = .balanced,
        extensibilityConfiguration: ExtensibilityConfiguration = .standard,
        initialCameraState: MapboxCameraState = .default,
        availableStyles: [MapboxStyle] = MapboxStyle.defaultStyles,
        developmentConfiguration: DevelopmentConfiguration = .production
    ) {
        self.renderingConfiguration = renderingConfiguration
        self.uiConfiguration = uiConfiguration
        self.performanceConfiguration = performanceConfiguration
        self.extensibilityConfiguration = extensibilityConfiguration
        self.initialCameraState = initialCameraState
        self.availableStyles = availableStyles
        self.developmentConfiguration = developmentConfiguration
    }
    
    // MARK: - Preset Configurations
    
    /// Medical facility discovery optimized configuration
    static let medicalFacilities = MapboxConfiguration(
        renderingConfiguration: .medicalOptimized,
        uiConfiguration: .accessibility,
        performanceConfiguration: .realTime,
        initialCameraState: .stLouis3D,
        availableStyles: [.standard, .satellite, .dark, .medicalCustom]
    )
    
    /// High-performance enterprise configuration
    static let enterpriseLevel = MapboxConfiguration(
        renderingConfiguration: .highPerformance,
        uiConfiguration: .professional,
        performanceConfiguration: .enterprise,
        extensibilityConfiguration: .fullFeatures,
        initialCameraState: .stLouis3D,
        availableStyles: MapboxStyle.allCases
    )
    
    /// Development and testing configuration
    static let development = MapboxConfiguration(
        renderingConfiguration: .debug,
        uiConfiguration: .developer,
        performanceConfiguration: .debug,
        extensibilityConfiguration: .experimental,
        developmentConfiguration: .development
    )
    
    // MARK: - Dynamic Configuration
    
    /// Show performance metrics overlay
    var showPerformanceMetrics: Bool {
        developmentConfiguration.showPerformanceMetrics
    }
    
    /// Enable experimental features
    var enableExperimentalFeatures: Bool {
        extensibilityConfiguration.enableExperimentalFeatures
    }
    
    /// Accessibility optimizations enabled
    var accessibilityOptimized: Bool {
        uiConfiguration.accessibilityOptimized
    }
    
    /// Validate configuration integrity
    func validate() throws {
        // Add basic validation
        if performanceConfiguration.targetFrameRate <= 0 {
            throw MapboxConfigurationError.invalidFrameRate
        }
        if performanceConfiguration.memoryThreshold <= 0 {
            throw MapboxConfigurationError.invalidMemoryThreshold
        }
    }
}

enum MapboxConfigurationError: Error {
    case invalidFrameRate
    case invalidMemoryThreshold
}

// MARK: - Rendering Configuration

/// **RenderingConfiguration**: 3D rendering engine settings and optimization
struct RenderingConfiguration: Equatable {
    
    // MARK: - 3D Rendering Features
    
    /// Enable advanced 3D terrain visualization
    let terrainEnabled: Bool
    
    /// Enable 3D buildings rendering
    let buildingsEnabled: Bool
    
    /// Enable realistic atmosphere and sky effects
    let atmosphereEnabled: Bool
    
    /// Enable advanced lighting calculations
    let advancedLightingEnabled: Bool
    
    /// Enable fog and atmospheric effects
    let fogEffectsEnabled: Bool
    
    /// Enable custom 3D extrusions (indoor/floorplan)
    let customExtrusionsEnabled: Bool
    
    // MARK: - Rendering Quality
    
    /// Target rendering quality level
    let qualityLevel: RenderingQuality
    
    /// Maximum number of 3D objects to render simultaneously
    let maxRenderObjects: Int
    
    /// Level of detail (LOD) configuration for 3D models
    let lodConfiguration: LODConfiguration
    
    /// Texture quality and compression settings
    let textureConfiguration: TextureConfiguration
    
    // MARK: - Performance Optimization
    
    /// Enable automatic quality scaling based on performance
    let adaptiveQualityEnabled: Bool
    
    /// Frame rate target (30, 45, 60 FPS)
    let targetFrameRate: Double
    
    /// Memory usage threshold for quality reduction
    let memoryThreshold: Int // MB
    
    /// GPU utilization threshold for optimization
    let gpuThreshold: Double // 0.0-1.0
    
    // MARK: - Preset Configurations
    
    /// Balanced performance and quality
    static let balanced = RenderingConfiguration(
        terrainEnabled: true,
        buildingsEnabled: true,
        atmosphereEnabled: true,
        advancedLightingEnabled: false,
        fogEffectsEnabled: true,
        customExtrusionsEnabled: true,
        qualityLevel: .medium,
        maxRenderObjects: 100,
        lodConfiguration: .balanced,
        textureConfiguration: .balanced,
        adaptiveQualityEnabled: true,
        targetFrameRate: 45.0,
        memoryThreshold: 150,
        gpuThreshold: 0.8
    )
    
    /// High-performance configuration for powerful devices
    static let highPerformance = RenderingConfiguration(
        terrainEnabled: true,
        buildingsEnabled: true,
        atmosphereEnabled: true,
        advancedLightingEnabled: true,
        fogEffectsEnabled: true,
        customExtrusionsEnabled: true,
        qualityLevel: .high,
        maxRenderObjects: 200,
        lodConfiguration: .highDetail,
        textureConfiguration: .highQuality,
        adaptiveQualityEnabled: true,
        targetFrameRate: 60.0,
        memoryThreshold: 300,
        gpuThreshold: 0.9
    )
    
    /// Medical facility optimized rendering
    static let medicalOptimized = RenderingConfiguration(
        terrainEnabled: true,
        buildingsEnabled: true,
        atmosphereEnabled: false,
        advancedLightingEnabled: false,
        fogEffectsEnabled: false,
        customExtrusionsEnabled: true,
        qualityLevel: .medium,
        maxRenderObjects: 75,
        lodConfiguration: .medicalFacilities,
        textureConfiguration: .medical,
        adaptiveQualityEnabled: true,
        targetFrameRate: 45.0,
        memoryThreshold: 120,
        gpuThreshold: 0.7
    )
    
    /// Debug configuration with maximum detail
    static let debug = RenderingConfiguration(
        terrainEnabled: true,
        buildingsEnabled: true,
        atmosphereEnabled: true,
        advancedLightingEnabled: true,
        fogEffectsEnabled: true,
        customExtrusionsEnabled: true,
        qualityLevel: .debug,
        maxRenderObjects: 50,
        lodConfiguration: .debug,
        textureConfiguration: .debug,
        adaptiveQualityEnabled: false,
        targetFrameRate: 30.0,
        memoryThreshold: 500,
        gpuThreshold: 1.0
    )
}

// MARK: - UI Configuration

/// **UIConfiguration**: User interface controls and interaction settings
struct UIConfiguration: Equatable {
    
    // MARK: - Control Visibility
    
    /// Show 3D/2D toggle button
    let show3DToggle: Bool
    
    /// Show camera controls (pitch, bearing, zoom)
    let showCameraControls: Bool
    
    /// Show style picker interface
    let showStylePicker: Bool
    
    /// Show performance metrics in UI
    let showPerformanceIndicators: Bool
    
    /// Show accessibility controls
    let showAccessibilityControls: Bool
    
    /// Show advanced feature toggles
    let showAdvancedControls: Bool
    
    // MARK: - Interaction Behavior
    
    /// Enable gesture-based camera control
    let gestureControlEnabled: Bool
    
    /// Enable haptic feedback for interactions
    let hapticFeedbackEnabled: Bool
    
    /// Animation duration for UI transitions
    let animationDuration: Double
    
    /// Enable smooth camera animations
    let smoothAnimationsEnabled: Bool
    
    // MARK: - Accessibility Features
    
    /// Optimize UI for accessibility users
    let accessibilityOptimized: Bool
    
    /// Enable VoiceOver announcements
    let voiceOverEnabled: Bool
    
    /// Enable high contrast mode support
    let highContrastSupport: Bool
    
    /// Enable reduced motion support
    let reducedMotionSupport: Bool
    
    // MARK: - Visual Appearance
    
    /// UI control theme (light, dark, auto)
    let theme: UITheme
    
    /// Control size (compact, standard, large)
    let controlSize: UIControlSize
    
    /// Corner radius for UI elements
    let cornerRadius: CGFloat
    
    /// Shadow configuration for controls
    let shadowConfiguration: UIShadowConfiguration
    
    // MARK: - Preset Configurations
    
    /// Standard UI configuration
    static let standard = UIConfiguration(
        show3DToggle: true,
        showCameraControls: true,
        showStylePicker: true,
        showPerformanceIndicators: false,
        showAccessibilityControls: false,
        showAdvancedControls: false,
        gestureControlEnabled: true,
        hapticFeedbackEnabled: true,
        animationDuration: 0.3,
        smoothAnimationsEnabled: true,
        accessibilityOptimized: false,
        voiceOverEnabled: true,
        highContrastSupport: true,
        reducedMotionSupport: true,
        theme: .auto,
        controlSize: .standard,
        cornerRadius: 12.0,
        shadowConfiguration: .standard
    )
    
    /// Professional interface for enterprise use
    static let professional = UIConfiguration(
        show3DToggle: true,
        showCameraControls: true,
        showStylePicker: true,
        showPerformanceIndicators: true,
        showAccessibilityControls: true,
        showAdvancedControls: true,
        gestureControlEnabled: true,
        hapticFeedbackEnabled: true,
        animationDuration: 0.2,
        smoothAnimationsEnabled: true,
        accessibilityOptimized: true,
        voiceOverEnabled: true,
        highContrastSupport: true,
        reducedMotionSupport: true,
        theme: .auto,
        controlSize: .standard,
        cornerRadius: 8.0,
        shadowConfiguration: .professional
    )
    
    /// Accessibility-focused configuration
    static let accessibility = UIConfiguration(
        show3DToggle: true,
        showCameraControls: true,
        showStylePicker: false,
        showPerformanceIndicators: false,
        showAccessibilityControls: true,
        showAdvancedControls: false,
        gestureControlEnabled: true,
        hapticFeedbackEnabled: true,
        animationDuration: 0.0, // No animations for accessibility
        smoothAnimationsEnabled: false,
        accessibilityOptimized: true,
        voiceOverEnabled: true,
        highContrastSupport: true,
        reducedMotionSupport: true,
        theme: .highContrast,
        controlSize: .large,
        cornerRadius: 4.0,
        shadowConfiguration: .accessibility
    )
    
    /// Developer interface with debugging tools
    static let developer = UIConfiguration(
        show3DToggle: true,
        showCameraControls: true,
        showStylePicker: true,
        showPerformanceIndicators: true,
        showAccessibilityControls: true,
        showAdvancedControls: true,
        gestureControlEnabled: true,
        hapticFeedbackEnabled: false,
        animationDuration: 0.1,
        smoothAnimationsEnabled: true,
        accessibilityOptimized: false,
        voiceOverEnabled: false,
        highContrastSupport: false,
        reducedMotionSupport: false,
        theme: .dark,
        controlSize: .compact,
        cornerRadius: 6.0,
        shadowConfiguration: .debug
    )
}

// MARK: - Performance Configuration

/// **PerformanceConfiguration**: Performance monitoring and optimization settings
struct PerformanceConfiguration: Equatable {
    
    // MARK: - Performance Targets
    
    /// Target frame rate for rendering
    let targetFrameRate: Double
    
    /// Memory usage threshold in MB
    let memoryThreshold: Int
    
    /// CPU usage threshold (0.0-1.0)
    let cpuThreshold: Double
    
    /// GPU usage threshold (0.0-1.0)
    let gpuThreshold: Double
    
    /// Battery level threshold for quality reduction
    let batteryThreshold: Double
    
    // MARK: - Monitoring Configuration
    
    /// Enable performance monitoring
    let monitoringEnabled: Bool
    
    /// Performance data collection interval
    let monitoringInterval: TimeInterval
    
    /// Enable automatic quality adjustment
    let autoQualityAdjustment: Bool
    
    /// Enable thermal state monitoring
    let thermalMonitoring: Bool
    
    // MARK: - Optimization Strategies
    
    /// Level of detail adjustment strategy
    let lodStrategy: LODStrategy
    
    /// Texture compression strategy
    let textureCompressionStrategy: TextureCompressionStrategy
    
    /// Culling strategy for off-screen objects
    let cullingStrategy: CullingStrategy
    
    /// Render pipeline optimization level
    let renderPipelineOptimization: RenderPipelineOptimization
    
    // MARK: - Preset Configurations
    
    /// Balanced performance configuration
    static let balanced = PerformanceConfiguration(
        targetFrameRate: 45.0,
        memoryThreshold: 150,
        cpuThreshold: 0.7,
        gpuThreshold: 0.8,
        batteryThreshold: 0.2,
        monitoringEnabled: true,
        monitoringInterval: 1.0,
        autoQualityAdjustment: true,
        thermalMonitoring: true,
        lodStrategy: .adaptive,
        textureCompressionStrategy: .balanced,
        cullingStrategy: .frustum,
        renderPipelineOptimization: .standard
    )
    
    /// Enterprise-grade performance configuration
    static let enterprise = PerformanceConfiguration(
        targetFrameRate: 60.0,
        memoryThreshold: 300,
        cpuThreshold: 0.8,
        gpuThreshold: 0.9,
        batteryThreshold: 0.1,
        monitoringEnabled: true,
        monitoringInterval: 0.5,
        autoQualityAdjustment: true,
        thermalMonitoring: true,
        lodStrategy: .enterprise,
        textureCompressionStrategy: .highQuality,
        cullingStrategy: .occlusion,
        renderPipelineOptimization: .maximum
    )
    
    /// Real-time performance for medical applications
    static let realTime = PerformanceConfiguration(
        targetFrameRate: 60.0,
        memoryThreshold: 100,
        cpuThreshold: 0.6,
        gpuThreshold: 0.7,
        batteryThreshold: 0.3,
        monitoringEnabled: true,
        monitoringInterval: 0.25,
        autoQualityAdjustment: true,
        thermalMonitoring: true,
        lodStrategy: .realTime,
        textureCompressionStrategy: .fast,
        cullingStrategy: .aggressive,
        renderPipelineOptimization: .realTime
    )
    
    /// Debug configuration with detailed monitoring
    static let debug = PerformanceConfiguration(
        targetFrameRate: 30.0,
        memoryThreshold: 500,
        cpuThreshold: 1.0,
        gpuThreshold: 1.0,
        batteryThreshold: 0.0,
        monitoringEnabled: true,
        monitoringInterval: 0.1,
        autoQualityAdjustment: false,
        thermalMonitoring: true,
        lodStrategy: .debug,
        textureCompressionStrategy: .none,
        cullingStrategy: .none,
        renderPipelineOptimization: .debug
    )
}

// MARK: - Extensibility Configuration

/// **ExtensibilityConfiguration**: Future features and extensibility settings
struct ExtensibilityConfiguration: Equatable {
    
    // MARK: - Future Features
    
    /// Enable experimental MapGPT integration readiness
    let mapGPTReadiness: Bool
    
    /// Enable voice/AI command processing preparation
    let voiceAIReadiness: Bool
    
    /// Enable GPX overlay system
    let gpxOverlaysEnabled: Bool
    
    /// Enable indoor navigation readiness
    let indoorNavigationReadiness: Bool
    
    /// Enable real-time collaboration features
    let collaborationReadiness: Bool
    
    /// Enable AR/VR integration preparation
    let arVrReadiness: Bool
    
    // MARK: - Plugin System
    
    /// Enable plugin architecture
    let pluginSystemEnabled: Bool
    
    /// Allowed plugin types
    let allowedPluginTypes: [PluginType]
    
    /// Enable experimental features
    let enableExperimentalFeatures: Bool
    
    /// API versioning strategy
    let apiVersioningStrategy: APIVersioningStrategy
    
    // MARK: - Data Integration
    
    /// Enable external data source integration
    let externalDataIntegration: Bool
    
    /// Enable real-time data streaming
    let realTimeDataStreaming: Bool
    
    /// Enable offline data synchronization
    let offlineDataSync: Bool
    
    /// Enable analytics and telemetry
    let analyticsEnabled: Bool
    
    // MARK: - Preset Configurations
    
    /// Standard extensibility features
    static let standard = ExtensibilityConfiguration(
        mapGPTReadiness: false,
        voiceAIReadiness: false,
        gpxOverlaysEnabled: true,
        indoorNavigationReadiness: false,
        collaborationReadiness: false,
        arVrReadiness: false,
        pluginSystemEnabled: false,
        allowedPluginTypes: [],
        enableExperimentalFeatures: false,
        apiVersioningStrategy: .stable,
        externalDataIntegration: true,
        realTimeDataStreaming: false,
        offlineDataSync: false,
        analyticsEnabled: false
    )
    
    /// Full features for enterprise deployment
    static let fullFeatures = ExtensibilityConfiguration(
        mapGPTReadiness: true,
        voiceAIReadiness: true,
        gpxOverlaysEnabled: true,
        indoorNavigationReadiness: true,
        collaborationReadiness: true,
        arVrReadiness: true,
        pluginSystemEnabled: true,
        allowedPluginTypes: PluginType.allCases,
        enableExperimentalFeatures: true,
        apiVersioningStrategy: .progressive,
        externalDataIntegration: true,
        realTimeDataStreaming: true,
        offlineDataSync: true,
        analyticsEnabled: true
    )
    
    /// Experimental features for development
    static let experimental = ExtensibilityConfiguration(
        mapGPTReadiness: true,
        voiceAIReadiness: true,
        gpxOverlaysEnabled: true,
        indoorNavigationReadiness: true,
        collaborationReadiness: true,
        arVrReadiness: true,
        pluginSystemEnabled: true,
        allowedPluginTypes: PluginType.allCases,
        enableExperimentalFeatures: true,
        apiVersioningStrategy: .experimental,
        externalDataIntegration: true,
        realTimeDataStreaming: true,
        offlineDataSync: true,
        analyticsEnabled: true
    )
}

// MARK: - Development Configuration

/// **DevelopmentConfiguration**: Development and debugging settings
struct DevelopmentConfiguration: Equatable {
    
    /// Show performance metrics overlay
    let showPerformanceMetrics: Bool
    
    /// Enable debug logging
    let debugLoggingEnabled: Bool
    
    /// Enable wireframe rendering mode
    let wireframeMode: Bool
    
    /// Enable bounding box visualization
    let showBoundingBoxes: Bool
    
    /// Enable memory leak detection
    let memoryLeakDetection: Bool
    
    /// Enable API call logging
    let apiCallLogging: Bool
    
    /// Production configuration
    static let production = DevelopmentConfiguration(
        showPerformanceMetrics: false,
        debugLoggingEnabled: false,
        wireframeMode: false,
        showBoundingBoxes: false,
        memoryLeakDetection: false,
        apiCallLogging: false
    )
    
    /// Development configuration
    static let development = DevelopmentConfiguration(
        showPerformanceMetrics: true,
        debugLoggingEnabled: true,
        wireframeMode: false,
        showBoundingBoxes: true,
        memoryLeakDetection: true,
        apiCallLogging: true
    )
}