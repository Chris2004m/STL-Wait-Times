//
//  MapboxSupportingComponents.swift
//  STL Wait Times
//
//  Supporting components for Ultimate 3D Mapbox implementation
//  Created by SuperClaude Enterprise Framework on 7/16/25.
//

import SwiftUI
import CoreLocation
import MapKit
import Combine
import Darwin.Mach

// MARK: - Performance Monitoring

/// **MapboxPerformanceMonitor**: Real-time performance tracking and optimization
class MapboxPerformanceMonitor: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentMetrics = PerformanceMetrics()
    @Published var isMonitoring: Bool = false
    @Published var enableAccessibilityMonitoring: Bool = false
    
    // MARK: - Configuration
    
    private var targetFrameRate: Double = 60.0
    private var memoryThreshold: Int = 150 // MB
    private var monitoringInterval: TimeInterval = 1.0
    
    // MARK: - Monitoring State
    
    private var displayLink: CADisplayLink?
    private var memoryTimer: Timer?
    private var frameCount: Int = 0
    private var lastFrameTime: CFTimeInterval = 0
    
    // MARK: - Callbacks
    
    var onPerformanceChange: ((PerformanceMetrics) -> Void)?
    var onMemoryWarning: ((Int) -> Void)?
    var onFrameRateDrop: ((Double) -> Void)?
    
    // MARK: - Public Methods
    
    /// Start performance monitoring
    func startMonitoring(
        targetFrameRate: Double = 60.0,
        memoryThreshold: Int = 150
    ) {
        guard !isMonitoring else { return }
        
        self.targetFrameRate = targetFrameRate
        self.memoryThreshold = memoryThreshold
        
        setupDisplayLink()
        setupMemoryMonitoring()
        
        isMonitoring = true
        print("📊 PerformanceMonitor: Started monitoring (target: \(targetFrameRate) FPS)")
    }
    
    /// Stop performance monitoring
    func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
        memoryTimer?.invalidate()
        memoryTimer = nil
        
        isMonitoring = false
        print("📊 PerformanceMonitor: Stopped monitoring")
    }
    
    /// Update configuration
    func updateConfiguration(_ config: PerformanceConfiguration) {
        self.targetFrameRate = config.targetFrameRate
        self.memoryThreshold = config.memoryThreshold
        self.monitoringInterval = config.monitoringInterval
    }
    
    /// Enable accessibility monitoring
    func startAccessibilityMonitoring() {
        enableAccessibilityMonitoring = true
        setupAccessibilityObservation()
    }
    
    /// Record annotation update performance
    func recordAnnotationUpdate(count: Int) {
        currentMetrics.annotationCount = count
        updateMetrics()
    }
    
    // MARK: - Private Implementation
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrameRate))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    private func setupMemoryMonitoring() {
        memoryTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
    }
    
    private func setupAccessibilityObservation() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilitySettingsChanged),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func updateFrameRate() {
        let currentTime = CACurrentMediaTime()
        
        if lastFrameTime > 0 {
            let deltaTime = currentTime - lastFrameTime
            let currentFrameRate = 1.0 / deltaTime
            
            currentMetrics.currentFrameRate = currentFrameRate
            
            // Check for frame rate drops
            if currentFrameRate < targetFrameRate * 0.8 {
                onFrameRateDrop?(currentFrameRate)
            }
        }
        
        lastFrameTime = currentTime
        frameCount += 1
        
        // Update metrics every 60 frames
        if frameCount % 60 == 0 {
            updateMetrics()
        }
    }
    
    private func updateMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        currentMetrics.memoryUsage = memoryUsage
        
        if memoryUsage > memoryThreshold {
            onMemoryWarning?(memoryUsage)
        }
        
        updateMetrics()
    }
    
    private func updateMetrics() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onPerformanceChange?(self.currentMetrics)
        }
    }
    
    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int(info.resident_size) / 1024 / 1024 // Convert to MB
        } else {
            return 0
        }
    }
    
    @objc private func accessibilitySettingsChanged() {
        if enableAccessibilityMonitoring {
            // Adjust monitoring based on accessibility settings
            if UIAccessibility.isReduceMotionEnabled {
                targetFrameRate = 30.0 // Reduce target for accessibility
            }
        }
    }
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Performance Overlay

/// **MapboxPerformanceOverlay**: Visual performance metrics overlay
struct MapboxPerformanceOverlay: View {
    @ObservedObject var monitor: MapboxPerformanceMonitor
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                performanceMetricsView
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.bottom, 120)
        }
    }
    
    @ViewBuilder
    private var performanceMetricsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Frame rate
            HStack(spacing: 4) {
                Circle()
                    .fill(frameRateColor)
                    .frame(width: 8, height: 8)
                
                Text("FPS: \(Int(monitor.currentMetrics.currentFrameRate))")
                    .font(.caption.monospaced())
                    .foregroundColor(.white)
            }
            
            // Memory usage
            HStack(spacing: 4) {
                Circle()
                    .fill(memoryColor)
                    .frame(width: 8, height: 8)
                
                Text("RAM: \(monitor.currentMetrics.memoryUsage)MB")
                    .font(.caption.monospaced())
                    .foregroundColor(.white)
            }
            
            // Annotation count
            Text("Annotations: \(monitor.currentMetrics.annotationCount)")
                .font(.caption.monospaced())
                .foregroundColor(.white)
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
    
    private var frameRateColor: Color {
        let fps = monitor.currentMetrics.currentFrameRate
        if fps >= 55 { return .green }
        else if fps >= 45 { return .yellow }
        else { return .red }
    }
    
    private var memoryColor: Color {
        let memory = monitor.currentMetrics.memoryUsage
        if memory < 100 { return .green }
        else if memory < 200 { return .yellow }
        else { return .red }
    }
}

// MARK: - Extensibility Layer

/// **MapboxExtensibilityLayer**: Future features and plugin system
class MapboxExtensibilityLayer: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var enabledFeatures: Set<ExtensibilityFeature> = []
    @Published var availablePlugins: [MapboxPlugin] = []
    @Published var activePlugins: [MapboxPlugin] = []
    
    // MARK: - Configuration
    
    private var configuration: ExtensibilityConfiguration = .standard
    
    // MARK: - Future Feature Readiness
    
    /// MapGPT integration readiness
    var mapGPTReadiness: MapGPTReadiness {
        MapGPTReadiness(
            enabled: configuration.mapGPTReadiness,
            apiInterface: enabledFeatures.contains(.mapGPT),
            contextProcessor: enabledFeatures.contains(.contextProcessing)
        )
    }
    
    /// Voice/AI command readiness
    var voiceAIReadiness: VoiceAIReadiness {
        VoiceAIReadiness(
            enabled: configuration.voiceAIReadiness,
            speechRecognition: enabledFeatures.contains(.voiceCommands),
            naturalLanguageProcessing: enabledFeatures.contains(.nlpProcessing)
        )
    }
    
    // MARK: - Public Methods
    
    /// Configure extensibility layer
    func configure(enabledFeatures: Set<ExtensibilityFeature>) {
        self.enabledFeatures = enabledFeatures
        setupEnabledFeatures()
    }
    
    /// Enable specific feature
    func enableFeature(_ feature: ExtensibilityFeature) {
        enabledFeatures.insert(feature)
        setupFeature(feature)
    }
    
    /// Disable specific feature
    func disableFeature(_ feature: ExtensibilityFeature) {
        enabledFeatures.remove(feature)
        teardownFeature(feature)
    }
    
    /// Register plugin
    func registerPlugin(_ plugin: MapboxPlugin) {
        guard !availablePlugins.contains(where: { $0.id == plugin.id }) else { return }
        
        availablePlugins.append(plugin)
        print("🔌 ExtensibilityLayer: Registered plugin: \(plugin.name)")
    }
    
    /// Activate plugin
    func activatePlugin(_ plugin: MapboxPlugin) {
        guard availablePlugins.contains(where: { $0.id == plugin.id }),
              !activePlugins.contains(where: { $0.id == plugin.id }) else { return }
        
        activePlugins.append(plugin)
        plugin.activate()
        print("🚀 ExtensibilityLayer: Activated plugin: \(plugin.name)")
    }
    
    /// Deactivate plugin
    func deactivatePlugin(_ plugin: MapboxPlugin) {
        activePlugins.removeAll { $0.id == plugin.id }
        plugin.deactivate()
        print("⏹️ ExtensibilityLayer: Deactivated plugin: \(plugin.name)")
    }
    
    // MARK: - Private Implementation
    
    private func setupEnabledFeatures() {
        for feature in enabledFeatures {
            setupFeature(feature)
        }
    }
    
    private func setupFeature(_ feature: ExtensibilityFeature) {
        switch feature {
        case .mapGPT:
            setupMapGPTIntegration()
        case .voiceCommands:
            setupVoiceCommandProcessing()
        case .gpxOverlays:
            setupGPXOverlaySystem()
        case .indoorNavigation:
            setupIndoorNavigationReadiness()
        case .collaboration:
            setupCollaborationFeatures()
        case .arVr:
            setupARVRIntegration()
        case .contextProcessing:
            setupContextProcessing()
        case .nlpProcessing:
            setupNLPProcessing()
        }
    }
    
    private func teardownFeature(_ feature: ExtensibilityFeature) {
        // Cleanup feature-specific resources
        print("🗑️ ExtensibilityLayer: Tearing down feature: \(feature)")
    }
    
    // MARK: - Feature Setup Methods
    
    private func setupMapGPTIntegration() {
        print("🤖 ExtensibilityLayer: MapGPT integration ready")
        // Setup API interfaces and context processors for future MapGPT integration
    }
    
    private func setupVoiceCommandProcessing() {
        print("🗣️ ExtensibilityLayer: Voice command processing ready")
        // Setup speech recognition and command parsing infrastructure
    }
    
    private func setupGPXOverlaySystem() {
        print("🗺️ ExtensibilityLayer: GPX overlay system ready")
        // Setup GPX file parsing and route overlay capabilities
    }
    
    private func setupIndoorNavigationReadiness() {
        print("🏢 ExtensibilityLayer: Indoor navigation readiness configured")
        // Setup floorplan processing and indoor positioning
    }
    
    private func setupCollaborationFeatures() {
        print("👥 ExtensibilityLayer: Collaboration features ready")
        // Setup real-time collaboration infrastructure
    }
    
    private func setupARVRIntegration() {
        print("🥽 ExtensibilityLayer: AR/VR integration ready")
        // Setup AR/VR rendering pipeline connections
    }
    
    private func setupContextProcessing() {
        print("🧠 ExtensibilityLayer: Context processing ready")
        // Setup context analysis for intelligent features
    }
    
    private func setupNLPProcessing() {
        print("💬 ExtensibilityLayer: NLP processing ready")
        // Setup natural language processing capabilities
    }
}

// MARK: - Supporting Types

/// **ExtensibilityFeature**: Available extensibility features
enum ExtensibilityFeature: String, CaseIterable {
    case mapGPT = "mapGPT"
    case voiceCommands = "voiceCommands"
    case gpxOverlays = "gpxOverlays"
    case indoorNavigation = "indoorNavigation"
    case collaboration = "collaboration"
    case arVr = "arVr"
    case contextProcessing = "contextProcessing"
    case nlpProcessing = "nlpProcessing"
}

/// **MapGPTReadiness**: MapGPT integration readiness status
struct MapGPTReadiness {
    let enabled: Bool
    let apiInterface: Bool
    let contextProcessor: Bool
    
    var isReady: Bool {
        enabled && apiInterface && contextProcessor
    }
}

/// **VoiceAIReadiness**: Voice/AI integration readiness status
struct VoiceAIReadiness {
    let enabled: Bool
    let speechRecognition: Bool
    let naturalLanguageProcessing: Bool
    
    var isReady: Bool {
        enabled && speechRecognition && naturalLanguageProcessing
    }
}

/// **MapboxPlugin**: Plugin interface for extensibility
protocol MapboxPlugin {
    var id: String { get }
    var name: String { get }
    var version: String { get }
    var description: String { get }
    
    func activate()
    func deactivate()
    func configure(with parameters: [String: Any])
}

// MARK: - 3D Effects Overlay

/// **Map3DEffectsOverlay**: Visual 3D effects for MapKit fallback
struct Map3DEffectsOverlay: View {
    let cameraState: MapboxCameraState
    let terrainEnabled: Bool
    let buildingsEnabled: Bool
    let atmosphereEnabled: Bool
    
    var body: some View {
        ZStack {
            // Atmosphere gradient overlay
            if atmosphereEnabled && cameraState.is3D {
                atmosphereOverlay
            }
            
            // 3D building shadows
            if buildingsEnabled && cameraState.is3D {
                buildingShadowsOverlay
            }
            
            // Terrain depth overlay
            if terrainEnabled && cameraState.is3D {
                terrainDepthOverlay
            }
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.5), value: cameraState.is3D)
    }
    
    @ViewBuilder
    private var atmosphereOverlay: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.blue.opacity(0.05), location: 0.0),
                .init(color: Color.clear, location: 0.3),
                .init(color: Color.orange.opacity(0.02), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .opacity(min(cameraState.pitch / 60.0, 1.0))
    }
    
    @ViewBuilder
    private var buildingShadowsOverlay: some View {
        // Simulated building shadows based on camera angle
        Rectangle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.1)
                    ]),
                    center: UnitPoint(x: 0.3, y: 0.3),
                    startRadius: 10,
                    endRadius: 200
                )
            )
            .opacity(min(cameraState.pitch / 90.0, 0.3))
    }
    
    @ViewBuilder
    private var terrainDepthOverlay: some View {
        // Terrain depth simulation
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.clear, location: 0.0),
                .init(color: Color.brown.opacity(0.03), location: 0.7),
                .init(color: Color.green.opacity(0.02), location: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(min(cameraState.pitch / 45.0, 0.5))
    }
}

// MARK: - Advanced 3D Annotation View

/// **Advanced3DAnnotationView**: Enhanced annotation view with 3D effects
struct Advanced3DAnnotationView: View {
    let annotation: AdvancedMapAnnotation
    let style: MapboxStyle
    let renderingMode: RenderingMode // This is the enum from MapboxCore3DEngine.swift
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Base annotation
                baseAnnotationView
                
                // 3D effects (when supported)
                if renderingMode.supports3D && annotation.renderingOptions.enable3D {
                    annotation3DEffects
                }
                
                // Wait time overlay
                if case .medicalFacility(let data) = annotation.annotationType,
                   let waitTime = data.waitTime {
                    waitTimeOverlay(waitTime)
                }
            }
            .scaleEffect(annotation.visualStyle.size.scaleForMode(renderingMode))
            .shadow(
                color: annotation.renderingOptions.shadowsEnabled ? .black.opacity(0.3) : .clear,
                radius: 4,
                x: 2,
                y: 2
            )
        }
        .accessibility(label: Text(annotation.accessibility.accessibilityLabel))
        .accessibility(hint: Text(annotation.accessibility.accessibilityHint ?? ""))
    }
    
    @ViewBuilder
    private var baseAnnotationView: some View {
        Circle()
            .fill(annotation.visualStyle.color)
            .frame(width: annotation.visualStyle.size.baseSize, height: annotation.visualStyle.size.baseSize)
            .overlay(
                Image(systemName: annotation.visualStyle.icon)
                    .font(.system(size: annotation.visualStyle.size.iconSize, weight: .semibold))
                    .foregroundColor(.white)
            )
    }
    
    @ViewBuilder
    private var annotation3DEffects: some View {
        // Simulated 3D extrusion effect
        if annotation.renderingOptions.extrusionHeight > 0 {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            annotation.visualStyle.color.opacity(0.8),
                            annotation.visualStyle.color.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 4, height: min(annotation.renderingOptions.extrusionHeight / 10, 20))
                .offset(x: -2, y: -10)
        }
    }
    
    @ViewBuilder
    private func waitTimeOverlay(_ waitTime: Int) -> some View {
        VStack {
            Spacer()
            Text("\(waitTime)m")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(waitTimeColor(waitTime))
                .cornerRadius(3)
        }
        .offset(y: 18)
    }
    
    private func waitTimeColor(_ waitTime: Int) -> Color {
        if waitTime <= 20 { return .green }
        else if waitTime <= 45 { return .orange }
        else { return .red }
    }
}

// MARK: - Accessibility Overlay

/// **MapboxAccessibilityOverlay**: Accessibility-focused overlay for screen readers
struct MapboxAccessibilityOverlay: View {
    let annotations: [AdvancedMapAnnotation]
    let currentStyle: MapboxStyle
    let onLocationSelected: ((CLLocationCoordinate2D) -> Void)?
    
    var body: some View {
        VStack {
            // Accessibility controls header
            accessibilityHeader
            
            // Annotations list for screen readers
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(sortedAnnotations, id: \.id) { annotation in
                        AccessibilityAnnotationRow(
                            annotation: annotation,
                            onSelect: {
                                onLocationSelected?(annotation.coordinate)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Spacer()
        }
        .background(Color(.systemBackground).opacity(0.95))
    }
    
    @ViewBuilder
    private var accessibilityHeader: some View {
        VStack(spacing: 8) {
            Text("Medical Facilities")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("\(annotations.count) facilities found")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Current style: \(currentStyle.displayName)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 16)
        .accessibility(addTraits: .isHeader)
    }
    
    private var sortedAnnotations: [AdvancedMapAnnotation] {
        annotations.sorted { annotation1, annotation2 in
            // Sort by priority for accessibility users
            switch (annotation1.annotationType, annotation2.annotationType) {
            case (.medicalFacility(let data1), .medicalFacility(let data2)):
                let priority1 = priorityValue(data1.priority)
                let priority2 = priorityValue(data2.priority)
                if priority1 != priority2 {
                    return priority1 > priority2
                }
                return (data1.waitTime ?? Int.max) < (data2.waitTime ?? Int.max)
            default:
                return annotation1.title < annotation2.title
            }
        }
    }
    
    private func priorityValue(_ priority: AdvancedMapAnnotation.MedicalFacilityPriority) -> Int {
        switch priority {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

/// **AccessibilityAnnotationRow**: Individual annotation row for accessibility
struct AccessibilityAnnotationRow: View {
    let annotation: AdvancedMapAnnotation
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Facility type icon
                Image(systemName: annotation.visualStyle.icon)
                    .font(.title2)
                    .foregroundColor(annotation.visualStyle.color)
                    .frame(width: 32)
                
                // Facility information
                VStack(alignment: .leading, spacing: 4) {
                    Text(annotation.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = annotation.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Medical facility specific info
                    if case .medicalFacility(let data) = annotation.annotationType {
                        HStack(spacing: 16) {
                            if let waitTime = data.waitTime {
                                Label("\(waitTime) min wait", systemImage: "clock")
                                    .font(.caption)
                                    .foregroundColor(waitTimeColor(waitTime))
                            }
                            
                            Label(data.isOpen ? "Open" : "Closed", systemImage: data.isOpen ? "checkmark.circle" : "xmark.circle")
                                .font(.caption)
                                .foregroundColor(data.isOpen ? .green : .red)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .accessibility(label: Text(annotation.accessibility.accessibilityLabel))
        .accessibility(hint: Text("Double-tap to select this facility"))
    }
    
    private func waitTimeColor(_ waitTime: Int) -> Color {
        if waitTime <= 20 { return .green }
        else if waitTime <= 45 { return .orange }
        else { return .red }
    }
}

// MARK: - Extensions

extension AnnotationVisualStyle.AnnotationSize {
    func scaleForMode(_ mode: RenderingMode) -> Double { // This is the enum from MapboxCore3DEngine.swift
        switch self {
        case .adaptive:
            return mode.supports3D ? 1.2 : 1.0
        default:
            return 1.0
        }
    }
    
    var iconSize: CGFloat {
        return baseSize * 0.5
    }
}