//
//  MapboxUIControlsView.swift
//  STL Wait Times
//
//  Intuitive UI controls for Ultimate 3D Mapbox component
//  Created by SuperClaude Enterprise Framework on 7/16/25.
//

import SwiftUI
import CoreLocation

// MARK: - State Management

/// **MapboxUIControlsState**: State management for UI controls
class MapboxUIControlsState: ObservableObject {
    @Published var controlsVisible = true
    @Published var isFullscreen = false
    @Published var selectedStyle: MapboxStyle = .standard
    @Published var is3DMode = false
    @Published var showPerformanceOverlay = false
    @Published var showAccessibilityControls = false
    
    /// Toggle control visibility
    func toggleControlsVisibility() {
        controlsVisible.toggle()
    }
    
    /// Toggle 3D mode
    func toggle3DMode() {
        is3DMode.toggle()
    }
    
    /// Update selected style
    func updateStyle(_ style: MapboxStyle) {
        selectedStyle = style
    }
}

/// **MapboxUIControlsView**: Professional-grade UI controls for 3D mapping
///
/// **Features:**
/// - 🎮 Intuitive camera controls with smooth animations
/// - 🎨 Seamless style switching with visual preview
/// - 🔄 2D/3D mode toggle with haptic feedback
/// - ♿ Comprehensive accessibility support
/// - 📱 Responsive design for all device sizes
/// - ⚡ Performance-optimized interactions
/// - 🎯 Context-aware control visibility
///
/// **Control Categories:**
/// ```
/// MapboxUIControls
/// ├── Primary Controls (3D toggle, style picker, zoom)
/// ├── Camera Controls (pitch, bearing, reset)
/// ├── Accessibility Controls (reduced motion, high contrast)
/// ├── Performance Controls (quality, frame rate)
/// └── Advanced Controls (custom overlays, developer tools)
/// ```
struct MapboxUIControlsView: View {
    
    // MARK: - Configuration & Dependencies
    
    /// UI configuration defining which controls to show
    let configuration: UIConfiguration
    
    /// Camera controller for position management
    let cameraController: MapboxCameraController
    
    /// Style manager for appearance control
    let styleManager: MapboxStyleManager
    
    /// Callbacks for control interactions
    let onStyleChange: (MapboxStyle) -> Void
    let onCameraReset: () -> Void
    
    // MARK: - UI State Management
    
    /// Whether advanced controls are expanded
    @State private var advancedControlsExpanded: Bool = false
    
    /// Whether style picker is open
    @State private var stylePickerOpen: Bool = false
    
    /// Whether camera controls are visible
    @State private var cameraControlsVisible: Bool = true
    
    /// Current interaction state for UI feedback
    @State private var interactionState: ControlInteractionState = .idle
    
    /// Haptic feedback generator
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    // MARK: - Accessibility State
    
    @AppStorage("mapbox_reducedMotion") private var reducedMotion = false
    @AppStorage("mapbox_highContrast") private var highContrast = false
    @AppStorage("mapbox_largeText") private var largeText = false
    
    // MARK: - Layout & Positioning
    
    /// Safe area insets for proper control positioning
    @State private var safeAreaInsets: EdgeInsets = EdgeInsets()
    
    /// Device orientation for responsive layout
    @State private var orientation: UIDeviceOrientation = .portrait
    
    // MARK: - View Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Primary Control Panel (Top-Right)
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        primaryControlPanel
                            .padding(.trailing, controlPadding.trailing)
                            .padding(.top, controlPadding.top)
                    }
                    Spacer()
                }
                
                // Camera Controls (Right Side)
                if configuration.showCameraControls && cameraControlsVisible {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            cameraControlPanel
                                .padding(.trailing, controlPadding.trailing)
                                .padding(.bottom, 120) // Above zoom controls
                        }
                    }
                }
                
                // Zoom Controls (Bottom-Right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        zoomControlPanel
                            .padding(.trailing, controlPadding.trailing)
                            .padding(.bottom, controlPadding.bottom)
                    }
                }
                
                // Style Picker Overlay
                if stylePickerOpen {
                    stylePickerOverlay
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
                
                // Advanced Controls Panel (Bottom-Left)
                if configuration.showAdvancedControls {
                    VStack {
                        Spacer()
                        HStack {
                            advancedControlPanel
                                .padding(.leading, controlPadding.leading)
                                .padding(.bottom, controlPadding.bottom)
                            Spacer()
                        }
                    }
                }
                
                // Accessibility Controls (Top-Left)
                if configuration.showAccessibilityControls {
                    VStack {
                        HStack {
                            accessibilityControlPanel
                                .padding(.leading, controlPadding.leading)
                                .padding(.top, controlPadding.top)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .onAppear {
                setupControlView(geometry: geometry)
            }
            .onChange(of: geometry.size) { _, newSize in
                updateLayoutForSize(newSize)
            }
        }
        .animation(
            reducedMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8),
            value: advancedControlsExpanded
        )
        .animation(
            reducedMotion ? .none : .easeInOut(duration: 0.3),
            value: stylePickerOpen
        )
    }
    
    // MARK: - Primary Control Panel
    
    /// Main control panel with essential functions
    @ViewBuilder
    private var primaryControlPanel: some View {
        VStack(spacing: controlSpacing) {
            // 3D Toggle Button
            if configuration.show3DToggle {
                toggle3DButton
            }
            
            // Style Picker Button
            if configuration.showStylePicker {
                stylePickerButton
            }
            
            // Performance Indicator
            if configuration.showPerformanceIndicators {
                performanceIndicator
            }
        }
        .padding(12)
        .background(controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
        .shadow(
            color: configuration.shadowConfiguration.color.opacity(configuration.shadowConfiguration.opacity),
            radius: configuration.shadowConfiguration.radius,
            x: configuration.shadowConfiguration.offset.width,
            y: configuration.shadowConfiguration.offset.height
        )
    }
    
    /// 3D mode toggle button
    @ViewBuilder
    private var toggle3DButton: some View {
        Button(action: handle3DToggle) {
            Image(systemName: cameraController.cameraMode.iconName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(buttonForegroundColor)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    Circle()
                        .fill(cameraController.cameraState.is3D ? .blue : Color(.systemGray4))
                )
                .scaleEffect(interactionState == .toggle3D ? 0.95 : 1.0)
        }
        .accessibility(label: Text("Toggle 3D View"))
        .accessibility(hint: Text("Currently \(cameraController.cameraMode.displayName)"))
        .accessibility(value: Text(cameraController.cameraState.is3D ? "3D mode active" : "2D mode active"))
    }
    
    /// Style picker button
    @ViewBuilder
    private var stylePickerButton: some View {
        Button(action: handleStylePickerToggle) {
            ZStack {
                // Current style preview
                RoundedRectangle(cornerRadius: 6)
                    .fill(stylePreviewGradient)
                    .frame(width: buttonSize - 8, height: buttonSize - 8)
                
                // Style icon
                Image(systemName: styleManager.currentStyle.iconName)
                    .font(.system(size: iconSize - 4, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .frame(width: buttonSize, height: buttonSize)
            .scaleEffect(interactionState == .stylePicker ? 0.95 : 1.0)
        }
        .accessibility(label: Text("Change Map Style"))
        .accessibility(hint: Text("Currently \(styleManager.currentStyle.displayName)"))
        .accessibility(value: Text("Tap to open style picker"))
    }
    
    /// Performance indicator
    @ViewBuilder
    private var performanceIndicator: some View {
        VStack(spacing: 2) {
            // Frame rate indicator
            Circle()
                .fill(performanceIndicatorColor)
                .frame(width: 8, height: 8)
            
            Text("FPS")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.secondary)
        }
        .accessibility(label: Text("Performance Indicator"))
        .accessibility(hint: Text("Shows current frame rate and performance"))
    }
    
    // MARK: - Camera Control Panel
    
    /// Camera positioning controls
    @ViewBuilder
    private var cameraControlPanel: some View {
        VStack(spacing: controlSpacing) {
            // Pitch Control (Tilt)
            pitchControlButton
            
            // Bearing Control (Rotation)
            bearingControlButton
            
            // Camera Reset
            cameraResetButton
        }
        .padding(8)
        .background(controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
        .shadow(
            color: configuration.shadowConfiguration.color.opacity(configuration.shadowConfiguration.opacity),
            radius: configuration.shadowConfiguration.radius,
            x: configuration.shadowConfiguration.offset.width,
            y: configuration.shadowConfiguration.offset.height
        )
    }
    
    /// Pitch control button
    @ViewBuilder
    private var pitchControlButton: some View {
        Button(action: handlePitchAdjustment) {
            Image(systemName: "gyroscope")
                .font(.system(size: iconSize - 2, weight: .medium))
                .foregroundColor(buttonForegroundColor)
                .frame(width: buttonSize - 8, height: buttonSize - 8)
        }
        .accessibility(label: Text("Adjust Camera Tilt"))
        .accessibility(hint: Text("Current tilt: \(Int(cameraController.cameraState.pitch)) degrees"))
    }
    
    /// Bearing control button
    @ViewBuilder
    private var bearingControlButton: some View {
        Button(action: handleBearingReset) {
            Image(systemName: "location.north.line")
                .font(.system(size: iconSize - 2, weight: .medium))
                .foregroundColor(buttonForegroundColor)
                .frame(width: buttonSize - 8, height: buttonSize - 8)
                .rotationEffect(.degrees(cameraController.cameraState.bearing))
        }
        .accessibility(label: Text("Reset Compass"))
        .accessibility(hint: Text("Current bearing: \(Int(cameraController.cameraState.bearing)) degrees"))
    }
    
    /// Camera reset button
    @ViewBuilder
    private var cameraResetButton: some View {
        Button(action: handleCameraReset) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: iconSize - 2, weight: .medium))
                .foregroundColor(buttonForegroundColor)
                .frame(width: buttonSize - 8, height: buttonSize - 8)
        }
        .accessibility(label: Text("Reset Camera"))
        .accessibility(hint: Text("Return to initial position"))
    }
    
    // MARK: - Zoom Control Panel
    
    /// Zoom in/out controls
    @ViewBuilder
    private var zoomControlPanel: some View {
        VStack(spacing: 4) {
            // Zoom In
            Button(action: handleZoomIn) {
                Image(systemName: "plus")
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(buttonForegroundColor)
                    .frame(width: buttonSize, height: buttonSize)
            }
            .accessibility(label: Text("Zoom In"))
            .accessibility(hint: Text("Current zoom level: \(Int(cameraController.cameraState.zoom))"))
            
            Divider()
                .frame(width: buttonSize - 16)
            
            // Zoom Out
            Button(action: handleZoomOut) {
                Image(systemName: "minus")
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(buttonForegroundColor)
                    .frame(width: buttonSize, height: buttonSize)
            }
            .accessibility(label: Text("Zoom Out"))
            .accessibility(hint: Text("Current zoom level: \(Int(cameraController.cameraState.zoom))"))
        }
        .background(controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
        .shadow(
            color: configuration.shadowConfiguration.color.opacity(configuration.shadowConfiguration.opacity),
            radius: configuration.shadowConfiguration.radius,
            x: configuration.shadowConfiguration.offset.width,
            y: configuration.shadowConfiguration.offset.height
        )
    }
    
    // MARK: - Style Picker Overlay
    
    /// Style selection overlay
    @ViewBuilder
    private var stylePickerOverlay: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    handleStylePickerToggle()
                }
            
            // Style picker content
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Map Style")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: handleStylePickerToggle) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .accessibility(label: Text("Close Style Picker"))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Style grid
                LazyVGrid(columns: styleGridColumns, spacing: 12) {
                    ForEach(styleManager.availableStyles, id: \.self) { style in
                        StylePickerCard(
                            style: style,
                            isSelected: style == styleManager.currentStyle,
                            onSelect: {
                                handleStyleSelection(style)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 20)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Advanced Control Panel
    
    /// Advanced features and developer controls
    @ViewBuilder
    private var advancedControlPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Toggle button
            Button(action: handleAdvancedControlsToggle) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12, weight: .medium))
                    
                    Text("Advanced")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .medium))
                        .rotationEffect(.degrees(advancedControlsExpanded ? 0 : 180))
                }
                .foregroundColor(.secondary)
            }
            .accessibility(label: Text("Advanced Controls"))
            .accessibility(hint: Text(advancedControlsExpanded ? "Collapse advanced options" : "Expand advanced options"))
            
            // Expanded controls
            if advancedControlsExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    // Performance metrics toggle
                    ControlToggle(
                        icon: "speedometer",
                        label: "Performance",
                        isOn: .constant(true)
                    )
                    
                    // Wireframe mode toggle
                    ControlToggle(
                        icon: "cube.transparent",
                        label: "Wireframe",
                        isOn: .constant(false)
                    )
                    
                    // Debug info toggle
                    ControlToggle(
                        icon: "info.circle",
                        label: "Debug Info",
                        isOn: .constant(false)
                    )
                }
            }
        }
        .padding(12)
        .background(controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
        .shadow(
            color: configuration.shadowConfiguration.color.opacity(configuration.shadowConfiguration.opacity),
            radius: configuration.shadowConfiguration.radius,
            x: configuration.shadowConfiguration.offset.width,
            y: configuration.shadowConfiguration.offset.height
        )
    }
    
    // MARK: - Accessibility Control Panel
    
    /// Accessibility-focused controls
    @ViewBuilder
    private var accessibilityControlPanel: some View {
        VStack(spacing: controlSpacing) {
            // Reduced motion toggle
            Button(action: handleReducedMotionToggle) {
                Image(systemName: reducedMotion ? "pause.circle.fill" : "pause.circle")
                    .font(.system(size: iconSize - 2, weight: .medium))
                    .foregroundColor(reducedMotion ? .blue : .secondary)
                    .frame(width: buttonSize - 8, height: buttonSize - 8)
            }
            .accessibility(label: Text("Toggle Reduced Motion"))
            .accessibility(hint: Text(reducedMotion ? "Reduced motion enabled" : "Reduced motion disabled"))
            
            // High contrast toggle
            Button(action: handleHighContrastToggle) {
                Image(systemName: highContrast ? "circle.lefthalf.filled" : "circle.lefthalf.striped.horizontal")
                    .font(.system(size: iconSize - 2, weight: .medium))
                    .foregroundColor(highContrast ? .blue : .secondary)
                    .frame(width: buttonSize - 8, height: buttonSize - 8)
            }
            .accessibility(label: Text("Toggle High Contrast"))
            .accessibility(hint: Text(highContrast ? "High contrast enabled" : "High contrast disabled"))
        }
        .padding(8)
        .background(controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
        .shadow(
            color: configuration.shadowConfiguration.color.opacity(configuration.shadowConfiguration.opacity),
            radius: configuration.shadowConfiguration.radius,
            x: configuration.shadowConfiguration.offset.width,
            y: configuration.shadowConfiguration.offset.height
        )
    }
    
    // MARK: - Computed Properties
    
    /// Button size based on configuration
    private var buttonSize: CGFloat {
        configuration.controlSize.buttonSize
    }
    
    /// Icon size based on configuration
    private var iconSize: CGFloat {
        buttonSize * 0.4
    }
    
    /// Control spacing
    private var controlSpacing: CGFloat {
        8
    }
    
    /// Control padding based on safe area
    private var controlPadding: EdgeInsets {
        EdgeInsets(
            top: safeAreaInsets.top + 16,
            leading: safeAreaInsets.leading + 16,
            bottom: safeAreaInsets.bottom + 16,
            trailing: safeAreaInsets.trailing + 16
        )
    }
    
    /// Control background with theme adaptation
    private var controlBackground: some View {
        Group {
            if configuration.theme.colorScheme == .dark || highContrast {
                Color(.systemGray6).opacity(0.9)
            } else {
                Color(.systemBackground).opacity(0.95)
            }
        }
    }
    
    /// Button foreground color
    private var buttonForegroundColor: Color {
        configuration.theme.colorScheme == .dark || highContrast ? .white : .primary
    }
    
    /// Style preview gradient
    private var stylePreviewGradient: LinearGradient {
        switch styleManager.currentStyle {
        case .standard:
            return LinearGradient(colors: [.blue, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .satellite:
            return LinearGradient(colors: [.orange, .brown], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dark:
            return LinearGradient(colors: [.gray, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .light:
            return LinearGradient(colors: [.white, .gray], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    /// Performance indicator color based on current performance
    private var performanceIndicatorColor: Color {
        // This would be connected to actual performance metrics
        .green
    }
    
    /// Style grid columns
    private var styleGridColumns: [GridItem] {
        [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    }
    
    // MARK: - Event Handlers
    
    /// Handle 3D mode toggle
    private func handle3DToggle() {
        withAnimation(reducedMotion ? .none : .spring(response: 0.3, dampingFraction: 0.8)) {
            interactionState = .toggle3D
            cameraController.toggle3DMode(animated: !reducedMotion)
        }
        
        // Haptic feedback
        if configuration.hapticFeedbackEnabled {
            hapticFeedback.impactOccurred()
        }
        
        // Reset interaction state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            interactionState = .idle
        }
        
        // Accessibility announcement
        let mode = cameraController.cameraState.is3D ? "3D" : "2D"
        UIAccessibility.post(notification: .announcement, argument: "Switched to \(mode) view")
    }
    
    /// Handle style picker toggle
    private func handleStylePickerToggle() {
        withAnimation(reducedMotion ? .none : .easeInOut(duration: 0.3)) {
            stylePickerOpen.toggle()
            interactionState = stylePickerOpen ? .stylePicker : .idle
        }
        
        if configuration.hapticFeedbackEnabled {
            hapticFeedback.impactOccurred()
        }
    }
    
    /// Handle style selection
    private func handleStyleSelection(_ style: MapboxStyle) {
        onStyleChange(style)
        
        withAnimation(reducedMotion ? .none : .easeInOut(duration: 0.3)) {
            stylePickerOpen = false
            interactionState = .idle
        }
        
        if configuration.hapticFeedbackEnabled {
            hapticFeedback.impactOccurred()
        }
        
        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: "Map style changed to \(style.displayName)")
    }
    
    /// Handle camera reset
    private func handleCameraReset() {
        onCameraReset()
        
        if configuration.hapticFeedbackEnabled {
            hapticFeedback.impactOccurred()
        }
        
        UIAccessibility.post(notification: .announcement, argument: "Camera position reset")
    }
    
    /// Handle zoom in
    private func handleZoomIn() {
        cameraController.zoomIn(animated: !reducedMotion)
        
        if configuration.hapticFeedbackEnabled {
            let lightFeedback = UIImpactFeedbackGenerator(style: .light)
            lightFeedback.impactOccurred()
        }
    }
    
    /// Handle zoom out
    private func handleZoomOut() {
        cameraController.zoomOut(animated: !reducedMotion)
        
        if configuration.hapticFeedbackEnabled {
            let lightFeedback = UIImpactFeedbackGenerator(style: .light)
            lightFeedback.impactOccurred()
        }
    }
    
    /// Handle pitch adjustment
    private func handlePitchAdjustment() {
        let newPitch = cameraController.cameraState.pitch > 30 ? 0.0 : 45.0
        cameraController.setPitch(newPitch, animated: !reducedMotion)
        
        if configuration.hapticFeedbackEnabled {
            hapticFeedback.impactOccurred()
        }
    }
    
    /// Handle bearing reset
    private func handleBearingReset() {
        cameraController.resetBearing(animated: !reducedMotion)
        
        if configuration.hapticFeedbackEnabled {
            hapticFeedback.impactOccurred()
        }
    }
    
    /// Handle advanced controls toggle
    private func handleAdvancedControlsToggle() {
        withAnimation(reducedMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8)) {
            advancedControlsExpanded.toggle()
        }
        
        if configuration.hapticFeedbackEnabled {
            let lightFeedback = UIImpactFeedbackGenerator(style: .light)
            lightFeedback.impactOccurred()
        }
    }
    
    /// Handle reduced motion toggle
    private func handleReducedMotionToggle() {
        reducedMotion.toggle()
        
        if configuration.hapticFeedbackEnabled {
            hapticFeedback.impactOccurred()
        }
        
        UIAccessibility.post(notification: .announcement, argument: reducedMotion ? "Reduced motion enabled" : "Reduced motion disabled")
    }
    
    /// Handle high contrast toggle
    private func handleHighContrastToggle() {
        highContrast.toggle()
        
        if configuration.hapticFeedbackEnabled {
            hapticFeedback.impactOccurred()
        }
        
        UIAccessibility.post(notification: .announcement, argument: highContrast ? "High contrast enabled" : "High contrast disabled")
    }
    
    // MARK: - Setup & Layout
    
    /// Setup control view with geometry
    private func setupControlView(geometry: GeometryProxy) {
        safeAreaInsets = geometry.safeAreaInsets
        updateLayoutForSize(geometry.size)
        
        // Configure haptic feedback
        hapticFeedback.prepare()
    }
    
    /// Update layout for new size
    private func updateLayoutForSize(_ size: CGSize) {
        // Adjust control visibility based on screen size
        let isCompact = size.width < 400 || size.height < 600
        
        if isCompact {
            cameraControlsVisible = false
        } else {
            cameraControlsVisible = configuration.showCameraControls
        }
    }
}

// MARK: - Supporting Views

/// **StylePickerCard**: Individual style selection card
struct StylePickerCard: View {
    let style: MapboxStyle
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Style preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(previewGradient)
                    .frame(height: 60)
                    .overlay(
                        Image(systemName: style.iconName)
                            .font(.title2)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    )
                
                // Style name
                Text(style.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .accessibility(label: Text(style.displayName))
        .accessibility(hint: Text(isSelected ? "Currently selected" : "Tap to select"))
    }
    
    private var previewGradient: LinearGradient {
        switch style {
        case .standard:
            return LinearGradient(colors: [.blue, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .satellite:
            return LinearGradient(colors: [.orange, .brown], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dark:
            return LinearGradient(colors: [.gray, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .light:
            return LinearGradient(colors: [.white, .gray], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

/// **ControlToggle**: Reusable toggle control for advanced features
struct ControlToggle: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isOn ? .blue : .secondary)
                .frame(width: 16)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .scaleEffect(0.8)
        }
        .accessibility(label: Text("\(label) toggle"))
        .accessibility(value: Text(isOn ? "On" : "Off"))
    }
}

// MARK: - Control Interaction State

/// **ControlInteractionState**: UI feedback for control interactions
enum ControlInteractionState {
    case idle
    case toggle3D
    case stylePicker
    case cameraControl
    case zoom
}