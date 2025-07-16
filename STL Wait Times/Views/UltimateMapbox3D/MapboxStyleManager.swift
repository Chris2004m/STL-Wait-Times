//
//  MapboxStyleManager.swift
//  STL Wait Times
//
//  Advanced style management system for Ultimate 3D Mapbox component
//  Created by SuperClaude Enterprise Framework on 7/16/25.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

/// **MapboxStyleManager**: Enterprise-grade style management and transition system
///
/// **Features:**
/// - 🎨 Seamless style transitions with visual continuity
/// - 🌓 Adaptive theming based on time of day and context
/// - 🏥 Medical facility optimized styling
/// - ♿ Accessibility-aware style configurations
/// - 🔄 Custom style creation and management
/// - ⚡ Performance-optimized style switching
/// - 🌐 Context-aware style recommendations
///
/// **Style Categories:**
/// ```
/// MapboxStyle
/// ├── Standard Styles (standard, satellite, dark, light)
/// ├── Medical Optimized (medicalCustom, emergency, accessibility)
/// ├── Navigation Styles (navigation, traffic, outdoor)
/// └── Custom Styles (user-defined, branded)
/// ```
class MapboxStyleManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently active map style
    @Published var currentStyle: MapboxStyle = .standard
    
    /// Available styles for user selection
    @Published var availableStyles: [MapboxStyle] = MapboxStyle.defaultStyles
    
    /// Style transition progress (0.0-1.0)
    @Published var transitionProgress: Double = 0.0
    
    /// Whether style is currently transitioning
    @Published var isTransitioning: Bool = false
    
    /// Adaptive theming enabled
    @Published var adaptiveThemingEnabled: Bool = true
    
    /// Medical optimization active
    @Published var medicalOptimizationActive: Bool = false
    
    // MARK: - Style Transition System
    
    /// Previous style for transition effects
    private var previousStyle: MapboxStyle?
    
    /// Style transition configuration
    private var transitionConfiguration: StyleTransitionConfiguration = .smooth
    
    /// Transition timer for animated style changes
    private var transitionTimer: Timer?
    
    /// Style change callbacks
    var onStyleChanged: ((MapboxStyle) -> Void)?
    var onTransitionComplete: ((MapboxStyle) -> Void)?
    
    // MARK: - Context-Aware Styling
    
    /// Current context for style recommendations
    private var currentContext: StyleContext = .general
    
    /// Time-based styling configuration
    private var timeBasedStyling: TimeBasedStylingConfiguration = .enabled
    
    /// Accessibility-based style adjustments
    private var accessibilityStyling: AccessibilityStylingConfiguration = .standard
    
    // MARK: - Performance & Caching
    
    /// Style cache for quick switching
    private var styleCache: [MapboxStyle: StyleCacheEntry] = [:]
    
    /// Preloaded styles for instant switching
    private var preloadedStyles: Set<MapboxStyle> = []
    
    // MARK: - Combine Subscriptions
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupTimeBasedStyling()
        setupAccessibilityObservation()
        preloadEssentialStyles()
    }
    
    // MARK: - Public Configuration
    
    /// Configure style manager with available styles and initial style
    func configure(availableStyles: [MapboxStyle], initialStyle: MapboxStyle) {
        self.availableStyles = availableStyles
        self.currentStyle = initialStyle
        
        // Preload all available styles for better performance
        preloadStyles(availableStyles)
        
        // Setup context-aware styling
        updateStyleContext(.medical)
        
        print("🎨 StyleManager: Configured with \(availableStyles.count) styles, initial: \(initialStyle.displayName)")
    }
    
    /// Update available styles
    func updateAvailableStyles(_ styles: [MapboxStyle]) {
        self.availableStyles = styles
        preloadStyles(styles)
    }
    
    /// Enable or disable medical facility optimization
    func setMedicalOptimization(_ enabled: Bool) {
        medicalOptimizationActive = enabled
        
        if enabled {
            // Switch to medical-optimized style if current style doesn't support medical features
            if !currentStyle.supportsMedicalOptimization {
                transitionToStyle(.medicalCustom)
            }
        }
    }
    
    // MARK: - Style Transitions
    
    /// Transition to new style with animation
    func transitionToStyle(
        _ newStyle: MapboxStyle,
        duration: TimeInterval? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard newStyle != currentStyle else {
            completion?(true)
            return
        }
        
        // Check if style is available
        guard availableStyles.contains(newStyle) else {
            print("⚠️ StyleManager: Style \(newStyle.displayName) not available")
            completion?(false)
            return
        }
        
        // Stop any current transition
        stopCurrentTransition()
        
        // Setup transition
        previousStyle = currentStyle
        let transitionDuration = duration ?? transitionConfiguration.defaultDuration
        
        // Start transition
        if transitionConfiguration.animated {
            animateStyleTransition(to: newStyle, duration: transitionDuration, completion: completion)
        } else {
            // Immediate transition
            applyStyleImmediate(newStyle)
            completion?(true)
        }
    }
    
    /// Apply style immediately without animation
    func applyStyleImmediate(_ style: MapboxStyle) {
        previousStyle = currentStyle
        currentStyle = style
        transitionProgress = 0.0
        isTransitioning = false
        
        // Notify listeners
        onStyleChanged?(style)
        
        print("🎨 StyleManager: Applied style: \(style.displayName)")
    }
    
    /// Get next style in rotation
    func getNextStyle() -> MapboxStyle {
        guard let currentIndex = availableStyles.firstIndex(of: currentStyle) else {
            return availableStyles.first ?? .standard
        }
        
        let nextIndex = (currentIndex + 1) % availableStyles.count
        return availableStyles[nextIndex]
    }
    
    /// Get previous style in rotation
    func getPreviousStyle() -> MapboxStyle {
        guard let currentIndex = availableStyles.firstIndex(of: currentStyle) else {
            return availableStyles.last ?? .standard
        }
        
        let previousIndex = currentIndex == 0 ? availableStyles.count - 1 : currentIndex - 1
        return availableStyles[previousIndex]
    }
    
    // MARK: - Context-Aware Styling
    
    /// Update style context for intelligent recommendations
    func updateStyleContext(_ context: StyleContext) {
        currentContext = context
        
        // Apply context-specific optimizations
        switch context {
        case .medical:
            enableMedicalOptimizations()
        case .navigation:
            enableNavigationOptimizations()
        case .accessibility:
            enableAccessibilityOptimizations()
        case .general:
            break
        }
    }
    
    /// Get recommended style for current context
    func getRecommendedStyle() -> MapboxStyle {
        switch currentContext {
        case .medical:
            return medicalOptimizationActive ? .medicalCustom : .standard
        case .navigation:
            return .navigation
        case .accessibility:
            return accessibilityStyling.highContrast ? .dark : .light
        case .general:
            return timeBasedStyling.enabled ? getTimeBasedStyle() : .standard
        }
    }
    
    /// Enable automatic style adaptation based on time of day
    func enableTimeBasedStyling(_ enabled: Bool) {
        timeBasedStyling.enabled = enabled
        
        if enabled {
            setupTimeBasedStyling()
        }
    }
    
    // MARK: - Accessibility Integration
    
    /// Configure accessibility-aware styling
    func configureAccessibilityStyling(_ config: AccessibilityStylingConfiguration) {
        accessibilityStyling = config
        
        if config.highContrast && !currentStyle.supportsHighContrast {
            transitionToStyle(.dark)
        }
        
        if config.reducedMotion {
            transitionConfiguration = .immediate
        }
    }
    
    /// Check if current style supports accessibility requirements
    func isCurrentStyleAccessible() -> Bool {
        return currentStyle.supportsAccessibility
    }
    
    // MARK: - Performance Optimization
    
    /// Preload styles for instant switching
    func preloadStyles(_ styles: [MapboxStyle]) {
        for style in styles {
            preloadStyle(style)
        }
    }
    
    /// Preload single style
    func preloadStyle(_ style: MapboxStyle) {
        guard !preloadedStyles.contains(style) else { return }
        
        // Cache style configuration
        let cacheEntry = StyleCacheEntry(
            style: style,
            preloadTime: Date(),
            configuration: createStyleConfiguration(for: style)
        )
        
        styleCache[style] = cacheEntry
        preloadedStyles.insert(style)
        
        print("📦 StyleManager: Preloaded style: \(style.displayName)")
    }
    
    /// Clear style cache to free memory
    func clearStyleCache() {
        styleCache.removeAll()
        preloadedStyles.removeAll()
        print("🗑️ StyleManager: Style cache cleared")
    }
    
    // MARK: - Private Implementation
    
    /// Animate style transition
    private func animateStyleTransition(
        to newStyle: MapboxStyle,
        duration: TimeInterval,
        completion: ((Bool) -> Void)?
    ) {
        isTransitioning = true
        transitionProgress = 0.0
        
        let startTime = Date()
        
        transitionTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)
            
            // Apply easing function
            let easedProgress = self.transitionConfiguration.easingFunction(progress)
            self.transitionProgress = easedProgress
            
            if progress >= 1.0 {
                // Transition complete
                self.completeStyleTransition(to: newStyle)
                completion?(true)
                timer.invalidate()
            }
        }
    }
    
    /// Complete style transition
    private func completeStyleTransition(to newStyle: MapboxStyle) {
        currentStyle = newStyle
        transitionProgress = 0.0
        isTransitioning = false
        previousStyle = nil
        
        // Notify listeners
        onStyleChanged?(newStyle)
        onTransitionComplete?(newStyle)
        
        print("✅ StyleManager: Transition completed to: \(newStyle.displayName)")
    }
    
    /// Stop current transition
    private func stopCurrentTransition() {
        transitionTimer?.invalidate()
        transitionTimer = nil
        isTransitioning = false
        transitionProgress = 0.0
    }
    
    /// Setup time-based styling observation
    private func setupTimeBasedStyling() {
        // Observe time changes for automatic style adaptation
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.updateTimeBasedStyle()
        }
    }
    
    /// Update style based on time of day
    private func updateTimeBasedStyle() {
        guard timeBasedStyling.enabled else { return }
        
        let recommendedStyle = getTimeBasedStyle()
        
        if recommendedStyle != currentStyle && adaptiveThemingEnabled {
            transitionToStyle(recommendedStyle)
        }
    }
    
    /// Get appropriate style for current time
    private func getTimeBasedStyle() -> MapboxStyle {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6..<18:
            // Daytime: use light/standard styles
            return medicalOptimizationActive ? .medicalCustom : .standard
        case 18..<22:
            // Evening: use satellite for better visibility
            return .satellite
        default:
            // Night: use dark style
            return .dark
        }
    }
    
    /// Setup accessibility observation
    private func setupAccessibilityObservation() {
        // Observe accessibility settings changes
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateAccessibilityConfiguration()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIAccessibility.darkerSystemColorsStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateAccessibilityConfiguration()
            }
            .store(in: &cancellables)
    }
    
    /// Update accessibility configuration based on system settings
    private func updateAccessibilityConfiguration() {
        let reducedMotion = UIAccessibility.isReduceMotionEnabled
        let highContrast = UIAccessibility.isDarkerSystemColorsEnabled
        
        accessibilityStyling = AccessibilityStylingConfiguration(
            highContrast: highContrast,
            reducedMotion: reducedMotion,
            enhancedReadability: true
        )
        
        configureAccessibilityStyling(accessibilityStyling)
    }
    
    /// Enable medical-specific optimizations
    private func enableMedicalOptimizations() {
        medicalOptimizationActive = true
        
        // Apply medical facility color scheme
        // Enhance emergency department visibility
        // Optimize for wait time color coding
    }
    
    /// Enable navigation-specific optimizations
    private func enableNavigationOptimizations() {
        // Enhance route visibility
        // Optimize for turn-by-turn guidance
        // Improve traffic visualization
    }
    
    /// Enable accessibility-specific optimizations
    private func enableAccessibilityOptimizations() {
        // Increase contrast
        // Simplify visual elements
        // Enhance VoiceOver compatibility
    }
    
    /// Preload essential styles for instant access
    private func preloadEssentialStyles() {
        let essentialStyles: [MapboxStyle] = [.standard, .dark, .medicalCustom]
        preloadStyles(essentialStyles)
    }
    
    /// Create style configuration for caching
    private func createStyleConfiguration(for style: MapboxStyle) -> StyleConfiguration {
        return StyleConfiguration(
            style: style,
            supportsAccessibility: style.supportsAccessibility,
            supportsMedical: style.supportsMedicalOptimization,
            supports3D: style.supports3D,
            colorScheme: style.colorScheme
        )
    }
}

// MARK: - Supporting Types

/// **StyleContext**: Context for intelligent style recommendations
enum StyleContext {
    case general
    case medical
    case navigation
    case accessibility
}

/// **StyleTransitionConfiguration**: Animation configuration for style transitions
struct StyleTransitionConfiguration {
    let animated: Bool
    let defaultDuration: TimeInterval
    let easingFunction: (Double) -> Double
    
    static let immediate = StyleTransitionConfiguration(
        animated: false,
        defaultDuration: 0.0,
        easingFunction: { $0 }
    )
    
    static let smooth = StyleTransitionConfiguration(
        animated: true,
        defaultDuration: 0.6,
        easingFunction: { progress in
            // Ease in-out cubic
            return progress < 0.5
                ? 4 * progress * progress * progress
                : 1 - pow(-2 * progress + 2, 3) / 2
        }
    )
    
    static let fast = StyleTransitionConfiguration(
        animated: true,
        defaultDuration: 0.3,
        easingFunction: { progress in
            // Ease out quad
            return 1 - (1 - progress) * (1 - progress)
        }
    )
}

/// **TimeBasedStylingConfiguration**: Configuration for automatic time-based styling
struct TimeBasedStylingConfiguration {
    var enabled: Bool
    let dayStyle: MapboxStyle
    let nightStyle: MapboxStyle
    let transitionHours: (evening: Int, morning: Int)
    
    static let enabled = TimeBasedStylingConfiguration(
        enabled: true,
        dayStyle: .standard,
        nightStyle: .dark,
        transitionHours: (evening: 18, morning: 6)
    )
    
    static let disabled = TimeBasedStylingConfiguration(
        enabled: false,
        dayStyle: .standard,
        nightStyle: .dark,
        transitionHours: (evening: 18, morning: 6)
    )
}

/// **AccessibilityStylingConfiguration**: Accessibility-specific style configuration
struct AccessibilityStylingConfiguration {
    let highContrast: Bool
    let reducedMotion: Bool
    let enhancedReadability: Bool
    
    static let standard = AccessibilityStylingConfiguration(
        highContrast: false,
        reducedMotion: false,
        enhancedReadability: false
    )
    
    static let enhanced = AccessibilityStylingConfiguration(
        highContrast: true,
        reducedMotion: true,
        enhancedReadability: true
    )
}

/// **StyleCacheEntry**: Cache entry for preloaded styles
struct StyleCacheEntry {
    let style: MapboxStyle
    let preloadTime: Date
    let configuration: StyleConfiguration
}

/// **StyleConfiguration**: Comprehensive style configuration data
struct StyleConfiguration {
    let style: MapboxStyle
    let supportsAccessibility: Bool
    let supportsMedical: Bool
    let supports3D: Bool
    let colorScheme: ColorScheme?
}

// MARK: - MapboxStyle Extensions

extension MapboxStyle {
    /// Whether this style supports accessibility features
    var supportsAccessibility: Bool {
        switch self {
        case .dark, .light, .medicalCustom:
            return true
        default:
            return false
        }
    }
    
    /// Whether this style supports high contrast mode
    var supportsHighContrast: Bool {
        switch self {
        case .dark, .light:
            return true
        default:
            return false
        }
    }
    
    /// Whether this style supports medical facility optimization
    var supportsMedicalOptimization: Bool {
        switch self {
        case .standard, .medicalCustom, .light:
            return true
        default:
            return false
        }
    }
    
    /// Associated color scheme for UI adaptation
    var colorScheme: ColorScheme? {
        switch self {
        case .dark:
            return .dark
        case .light:
            return .light
        default:
            return nil
        }
    }
    
    /// Performance cost rating (1-5, where 5 is most expensive)
    var performanceCost: Int {
        switch self {
        case .standard, .light:
            return 1
        case .dark, .medicalCustom:
            return 2
        case .satellite, .outdoors:
            return 4
        case .navigation, .traffic:
            return 5
        }
    }
}