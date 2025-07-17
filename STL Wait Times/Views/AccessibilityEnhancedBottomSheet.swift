import SwiftUI
import UIKit
import AVFoundation

/// **AccessibilityEnhancedBottomSheet**: Ultra-accessible bottom sheet with advanced VoiceOver support
///
/// Features:
/// - VoiceOver custom actions and gestures
/// - Reduce Motion compliance
/// - Dynamic Type support
/// - Custom accessibility elements
/// - Haptic feedback patterns
/// - Audio cues for state changes
struct AccessibilityEnhancedBottomSheet<Content: View>: View {
    
    // MARK: - Public Properties
    
    @Binding var state: BottomSheetState
    let content: Content
    let configuration: BottomSheetAccessibilityConfiguration
    var onStateChange: ((BottomSheetState) -> Void)?
    
    // MARK: - Private State
    
    /// Accessibility preferences
    @Environment(\.accessibilityEnabled) private var accessibilityEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    /// Voice Over state
    @State private var voiceOverEnabled: Bool = false
    @State private var lastStateAnnouncement: Date = Date()
    
    /// Haptic feedback generators
    @State private var impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    @State private var selectionFeedback = UISelectionFeedbackGenerator()
    @State private var notificationFeedback = UINotificationFeedbackGenerator()
    
    /// Audio feedback
    @State private var audioSession: AVAudioSession?
    
    // MARK: - Initialization
    
    init(
        state: Binding<BottomSheetState>,
        configuration: BottomSheetAccessibilityConfiguration = BottomSheetAccessibilityConfiguration(),
        onStateChange: ((BottomSheetState) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self._state = state
        self.configuration = configuration
        self.onStateChange = onStateChange
        self.content = content()
    }
    
    // MARK: - View Body
    
    var body: some View {
        UltimateBottomSheetView(
            state: $state,
            configuration: adaptedConfiguration,
            onStateChange: handleStateChange
        ) {
            accessibilityEnhancedContent
        }
        .onAppear {
            setupAccessibility()
        }
        .onChange(of: state) { _, newState in
            handleAccessibilityStateChange(newState)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(sheetAccessibilityLabel)
        .accessibilityHint(sheetAccessibilityHint)
        .accessibilityActions {
            sheetAccessibilityActions
        }
    }
    
    // MARK: - Accessibility Enhanced Content
    
    @ViewBuilder
    private var accessibilityEnhancedContent: some View {
        VStack(spacing: 0) {
            // Accessibility header
            if voiceOverEnabled {
                accessibilityHeaderView
            }
            
            // Main content with accessibility enhancements
            content
                .accessibilityElement(children: .contain)
                .accessibilityAdjustableAction { direction in
                    handleAccessibilityAdjustment(direction)
                }
        }
    }
    
    // MARK: - Accessibility Header
    
    @ViewBuilder
    private var accessibilityHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(configuration.accessibilityTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(state.accessibilityDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // State indicator for VoiceOver
            Image(systemName: state.accessibilityIcon)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(configuration.accessibilityTitle), \(state.accessibilityDescription)")
        .accessibilityAddTraits(.isHeader)
    }
    
    // MARK: - Accessibility Properties
    
    private var sheetAccessibilityLabel: String {
        "\(configuration.accessibilityTitle), \(state.accessibilityDescription)"
    }
    
    private var sheetAccessibilityHint: String {
        if voiceOverEnabled {
            return "Swipe up or down to change sheet size. Available actions: \(availableActions.joined(separator: ", "))"
        } else {
            return "Drag to resize panel"
        }
    }
    
    private var availableActions: [String] {
        var actions: [String] = []
        
        if state != .expanded {
            actions.append("Expand")
        }
        if state != .peek {
            actions.append("Collapse")
        }
        if state != .medium {
            actions.append("Medium size")
        }
        
        return actions
    }
    
    // MARK: - Accessibility Actions
    
    @ViewBuilder
    private var sheetAccessibilityActions: some View {
        if state != .expanded {
            Button("Expand") {
                animateToState(.expanded)
            }
        }
        
        if state != .medium {
            Button("Medium size") {
                animateToState(.medium)
            }
        }
        
        if state != .peek {
            Button("Collapse") {
                animateToState(.peek)
            }
        }
    }
    
    // MARK: - Adapted Configuration
    
    private var adaptedConfiguration: SheetConfiguration {
        var config = SheetConfiguration()
        
        // Adapt for reduced motion
        if reduceMotion {
            config = SheetConfiguration(
                springResponse: 0.2,
                springDamping: 1.0,
                velocityThreshold: 500.0,
                elasticResistance: 0.1
            )
        }
        
        // Adapt for dynamic type
        if dynamicTypeSize >= .xLarge {
            config = SheetConfiguration(
                handleHeight: 8,
                handlePadding: 16
            )
        }
        
        return config
    }
    
    // MARK: - Setup and Handlers
    
    private func setupAccessibility() {
        // Check VoiceOver status
        voiceOverEnabled = UIAccessibility.isVoiceOverRunning
        
        // Setup audio session for audio feedback
        setupAudioSession()
        
        // Prepare haptic feedback
        impactFeedback.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
        
        // Listen for VoiceOver changes
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            voiceOverEnabled = UIAccessibility.isVoiceOverRunning
        }
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession?.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession?.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func handleStateChange(_ newState: BottomSheetState) {
        // Call parent handler
        onStateChange?(newState)
        
        // Handle accessibility state change
        handleAccessibilityStateChange(newState)
    }
    
    private func handleAccessibilityStateChange(_ newState: BottomSheetState) {
        // Throttle announcements
        let now = Date()
        guard now.timeIntervalSince(lastStateAnnouncement) > 0.5 else { return }
        lastStateAnnouncement = now
        
        // VoiceOver announcement
        if voiceOverEnabled {
            let announcement = "\(configuration.accessibilityTitle) \(newState.accessibilityDescription)"
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
        
        // Haptic feedback
        provideHapticFeedback(for: newState)
        
        // Audio feedback
        provideAudioFeedback(for: newState)
    }
    
    private func handleAccessibilityAdjustment(_ direction: AccessibilityAdjustmentDirection) {
        switch direction {
        case .increment:
            animateToState(state.nextStateUp)
        case .decrement:
            animateToState(state.nextStateDown)
        @unknown default:
            break
        }
    }
    
    private func animateToState(_ targetState: BottomSheetState) {
        let animation: Animation = reduceMotion ? .linear(duration: 0.1) : .spring(response: 0.4, dampingFraction: 0.8)
        
        withAnimation(animation) {
            state = targetState
        }
    }
    
    // MARK: - Feedback Systems
    
    private func provideHapticFeedback(for state: BottomSheetState) {
        switch state {
        case .peek:
            impactFeedback.impactOccurred(intensity: 0.7)
        case .medium:
            impactFeedback.impactOccurred(intensity: 0.8)
        case .expanded:
            impactFeedback.impactOccurred(intensity: 1.0)
        }
    }
    
    private func provideAudioFeedback(for state: BottomSheetState) {
        guard !voiceOverEnabled else { return } // Don't interfere with VoiceOver
        
        // Simple audio feedback using system sounds
        let soundID: SystemSoundID = switch state {
        case .peek: 1104 // Tock
        case .medium: 1105 // Tock
        case .expanded: 1106 // Tock
        }
        
        AudioServicesPlaySystemSound(soundID)
    }
}

// MARK: - Accessibility Configuration

struct BottomSheetAccessibilityConfiguration {
    let accessibilityTitle: String
    let enableVoiceOverSupport: Bool
    let enableHapticFeedback: Bool
    let enableAudioFeedback: Bool
    let customAccessibilityActions: [AccessibilityAction]
    
    init(
        accessibilityTitle: String = "Medical Facilities Panel",
        enableVoiceOverSupport: Bool = true,
        enableHapticFeedback: Bool = true,
        enableAudioFeedback: Bool = true,
        customAccessibilityActions: [AccessibilityAction] = []
    ) {
        self.accessibilityTitle = accessibilityTitle
        self.enableVoiceOverSupport = enableVoiceOverSupport
        self.enableHapticFeedback = enableHapticFeedback
        self.enableAudioFeedback = enableAudioFeedback
        self.customAccessibilityActions = customAccessibilityActions
    }
}

struct AccessibilityAction {
    let name: String
    let action: () -> Void
}

// MARK: - BottomSheetState Extensions

extension BottomSheetState {
    // accessibilityDescription is already defined in SimpleBottomSheetView.swift
    
    var accessibilityIcon: String {
        switch self {
        case .peek:
            return "chevron.up"
        case .medium:
            return "equal"
        case .expanded:
            return "chevron.down"
        }
    }
}

// MARK: - Preview

#Preview("Accessibility Enhanced Bottom Sheet") {
    AccessibilityEnhancedBottomSheet(
        state: .constant(.peek),
        configuration: BottomSheetAccessibilityConfiguration(
            accessibilityTitle: "Medical Facilities",
            enableVoiceOverSupport: true,
            enableHapticFeedback: true,
            enableAudioFeedback: true
        )
    ) {
        VStack {
            Text("Accessible Content")
                .font(.title2)
                .padding()
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(0..<10) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                            .frame(height: 80)
                            .overlay(
                                Text("Facility \(index + 1)")
                                    .font(.headline)
                            )
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Facility \(index + 1)")
                            .accessibilityHint("Double-tap for details")
                    }
                }
                .padding()
            }
        }
    }
}