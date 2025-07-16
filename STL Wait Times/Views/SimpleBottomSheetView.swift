import SwiftUI
import UIKit

/// **SimpleBottomSheetView**: Reliable swipe-based bottom sheet with haptic feedback
///
/// Features:
/// - Simple swipe gesture recognition (up/down)
/// - Haptic feedback for each state transition
/// - Clean animations without complex physics
/// - Modular and maintainable code structure
/// - Comprehensive accessibility support
/// - Performance optimized for 60fps
///
/// Usage:
/// ```swift
/// SimpleBottomSheetView(
///     state: $sheetState,
///     configuration: SimpleSheetConfiguration()
/// ) {
///     // Your content here
/// }
/// ```
struct SimpleBottomSheetView<Content: View>: View {
    
    // MARK: - Public Properties
    
    /// Current sheet state binding
    @Binding var state: BottomSheetState
    
    /// Content to display in the sheet
    let content: Content
    
    /// Configuration for sheet behavior
    let configuration: SimpleSheetConfiguration
    
    /// Callback when state changes
    var onStateChange: ((BottomSheetState) -> Void)?
    
    // MARK: - Private State
    
    /// Haptic feedback generator for state transitions
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    /// Selection feedback for button interactions
    @State private var selectionFeedback = UISelectionFeedbackGenerator()
    
    /// Tracks if we're currently animating to prevent gesture conflicts
    @State private var isAnimating = false
    
    /// Accessibility support
    @Environment(\.accessibilityEnabled) private var accessibilityEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // MARK: - Initialization
    
    /// Initialize the simple bottom sheet
    /// - Parameters:
    ///   - state: Binding to the current sheet state
    ///   - configuration: Configuration for sheet behavior
    ///   - onStateChange: Optional callback for state changes
    ///   - content: Content to display in the sheet
    init(
        state: Binding<BottomSheetState>,
        configuration: SimpleSheetConfiguration = SimpleSheetConfiguration(),
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
        GeometryReader { geometry in
            ZStack {
                // Background overlay that dims based on sheet state
                backgroundOverlay(geometry: geometry)
                
                // Main sheet content with swipe gesture
                sheetContent(geometry: geometry)
                    .offset(y: offsetForCurrentState(geometry: geometry))
                    .gesture(swipeGesture(geometry: geometry))
                    .animation(sheetAnimation, value: state)
            }
        }
        .onAppear {
            setupHapticFeedback()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityActions {
            accessibilityActions
        }
    }
    
    // MARK: - Sheet Content
    
    /// Main content view with handle and content
    @ViewBuilder
    private func sheetContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Drag handle
            dragHandle
                .padding(.top, configuration.handlePadding)
            
            // Content area
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(sheetBackground)
        .cornerRadius(configuration.cornerRadius, corners: [.topLeft, .topRight])
        .shadow(
            color: shadowColor,
            radius: configuration.shadowRadius,
            x: 0,
            y: -configuration.shadowRadius / 2
        )
    }
    
    /// Drag handle view
    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: configuration.handleHeight / 2)
            .fill(configuration.handleColor)
            .frame(
                width: configuration.handleWidth,
                height: configuration.handleHeight
            )
            .accessibilityHidden(true)
    }
    
    /// Sheet background with proper opacity
    private var sheetBackground: some View {
        configuration.backgroundColor
            .opacity(configuration.backgroundOpacity)
    }
    
    /// Background overlay that dims the content behind the sheet
    @ViewBuilder
    private func backgroundOverlay(geometry: GeometryProxy) -> some View {
        Color.black
            .opacity(backgroundOpacityForState)
            .ignoresSafeArea()
            .onTapGesture {
                if state != .peek {
                    animateToState(.peek)
                }
            }
    }
    
    // MARK: - Gestures
    
    /// Simple swipe gesture recognizer
    private func swipeGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .onEnded { value in
                handleSwipeGesture(value: value, geometry: geometry)
            }
    }
    
    /// Handle swipe gesture completion
    /// - Parameters:
    ///   - value: The drag gesture value
    ///   - geometry: Geometry proxy for size calculations
    private func handleSwipeGesture(value: DragGesture.Value, geometry: GeometryProxy) {
        // Prevent gesture handling during animations
        guard !isAnimating else { return }
        
        // Calculate swipe direction and distance
        let swipeDistance = value.translation.height
        let minSwipeDistance = configuration.minSwipeDistance
        
        // Determine new state based on swipe direction
        let newState: BottomSheetState
        
        if swipeDistance < -minSwipeDistance {
            // Swipe up - move to next state
            newState = state.nextStateUp
        } else if swipeDistance > minSwipeDistance {
            // Swipe down - move to previous state
            newState = state.nextStateDown
        } else {
            // Swipe too short - stay in current state
            return
        }
        
        // Only animate if state actually changes
        if newState != state {
            animateToState(newState)
        }
    }
    
    // MARK: - Animations & State Management
    
    /// Animate to a new state with haptic feedback
    /// - Parameter newState: The target state
    private func animateToState(_ newState: BottomSheetState) {
        // Prevent concurrent animations
        guard !isAnimating else { return }
        
        // Provide haptic feedback
        provideHapticFeedback(for: newState)
        
        // Set animation flag
        isAnimating = true
        
        // Animate to new state
        withAnimation(sheetAnimation) {
            state = newState
        }
        
        // Call state change callback
        onStateChange?(newState)
        
        // Announce state change for accessibility
        announceStateChange(newState)
        
        // Reset animation flag after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + sheetAnimation.duration) {
            isAnimating = false
        }
    }
    
    /// Animation used for sheet transitions
    private var sheetAnimation: Animation {
        if reduceMotion {
            return .linear(duration: 0.2)
        } else {
            return .spring(
                response: configuration.animationResponse,
                dampingFraction: configuration.animationDamping
            )
        }
    }
    
    // MARK: - Layout Calculations
    
    /// Calculate offset for current state
    /// - Parameter geometry: Geometry proxy for size calculations
    /// - Returns: Y offset for the sheet
    private func offsetForCurrentState(geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        
        switch state {
        case .peek:
            return screenHeight * configuration.peekRatio
        case .medium:
            return screenHeight * configuration.mediumRatio
        case .expanded:
            return screenHeight * configuration.expandedRatio
        }
    }
    
    /// Background opacity based on current state
    private var backgroundOpacityForState: Double {
        switch state {
        case .peek:
            return 0.0
        case .medium:
            return 0.2
        case .expanded:
            return 0.4
        }
    }
    
    /// Shadow color based on current state
    private var shadowColor: Color {
        Color.black.opacity(backgroundOpacityForState + 0.1)
    }
    
    // MARK: - Haptic Feedback
    
    /// Setup haptic feedback generators
    private func setupHapticFeedback() {
        hapticFeedback.prepare()
        selectionFeedback.prepare()
    }
    
    /// Provide haptic feedback for state transitions
    /// - Parameter newState: The state we're transitioning to
    private func provideHapticFeedback(for newState: BottomSheetState) {
        switch newState {
        case .peek:
            hapticFeedback.impactOccurred(intensity: 0.7)
        case .medium:
            hapticFeedback.impactOccurred(intensity: 0.8)
        case .expanded:
            hapticFeedback.impactOccurred(intensity: 1.0)
        }
    }
    
    // MARK: - Accessibility
    
    /// Accessibility label for the sheet
    private var accessibilityLabel: String {
        "Bottom sheet, currently \(state.accessibilityDescription)"
    }
    
    /// Accessibility hint for the sheet
    private var accessibilityHint: String {
        "Swipe up to expand, swipe down to collapse"
    }
    
    /// Accessibility actions for the sheet
    @ViewBuilder
    private var accessibilityActions: some View {
        if state != .expanded {
            Button("Expand") {
                animateToState(state.nextStateUp)
            }
        }
        
        if state != .peek {
            Button("Collapse") {
                animateToState(state.nextStateDown)
            }
        }
        
        if state != .medium {
            Button("Medium size") {
                animateToState(.medium)
            }
        }
    }
    
    /// Announce state change for accessibility
    /// - Parameter newState: The new state
    private func announceStateChange(_ newState: BottomSheetState) {
        guard accessibilityEnabled else { return }
        
        let announcement = "Sheet \(newState.accessibilityDescription)"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}

// MARK: - Configuration

/// Configuration for simple bottom sheet behavior
struct SimpleSheetConfiguration {
    // MARK: - Position Ratios
    
    /// Ratio for peek state (0 = top, 1 = bottom)
    let peekRatio: CGFloat
    
    /// Ratio for medium state
    let mediumRatio: CGFloat
    
    /// Ratio for expanded state
    let expandedRatio: CGFloat
    
    // MARK: - Animation Properties
    
    /// Animation response time
    let animationResponse: Double
    
    /// Animation damping fraction
    let animationDamping: Double
    
    /// Minimum swipe distance to trigger state change
    let minSwipeDistance: CGFloat
    
    // MARK: - Appearance
    
    /// Corner radius for the sheet
    let cornerRadius: CGFloat
    
    /// Background color of the sheet
    let backgroundColor: Color
    
    /// Background opacity
    let backgroundOpacity: Double
    
    /// Shadow radius
    let shadowRadius: CGFloat
    
    // MARK: - Handle Properties
    
    /// Width of the drag handle
    let handleWidth: CGFloat
    
    /// Height of the drag handle
    let handleHeight: CGFloat
    
    /// Color of the drag handle
    let handleColor: Color
    
    /// Padding around the handle
    let handlePadding: CGFloat
    
    // MARK: - Initialization
    
    /// Initialize configuration with default values
    init(
        peekRatio: CGFloat = 0.72,
        mediumRatio: CGFloat = 0.43,
        expandedRatio: CGFloat = 0.06,
        animationResponse: Double = 0.4,
        animationDamping: Double = 0.8,
        minSwipeDistance: CGFloat = 50.0,
        cornerRadius: CGFloat = 20,
        backgroundColor: Color = Color(.systemBackground),
        backgroundOpacity: Double = 0.98,
        shadowRadius: CGFloat = 10,
        handleWidth: CGFloat = 40,
        handleHeight: CGFloat = 5,
        handleColor: Color = Color(.systemGray4),
        handlePadding: CGFloat = 10
    ) {
        self.peekRatio = peekRatio
        self.mediumRatio = mediumRatio
        self.expandedRatio = expandedRatio
        self.animationResponse = animationResponse
        self.animationDamping = animationDamping
        self.minSwipeDistance = minSwipeDistance
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.backgroundOpacity = backgroundOpacity
        self.shadowRadius = shadowRadius
        self.handleWidth = handleWidth
        self.handleHeight = handleHeight
        self.handleColor = handleColor
        self.handlePadding = handlePadding
    }
}

// MARK: - BottomSheetState Extensions

extension BottomSheetState {
    /// Next state when swiping up
    var nextStateUp: BottomSheetState {
        switch self {
        case .peek: return .medium
        case .medium: return .expanded
        case .expanded: return .expanded // Already at maximum
        }
    }
    
    /// Next state when swiping down
    var nextStateDown: BottomSheetState {
        switch self {
        case .expanded: return .medium
        case .medium: return .peek
        case .peek: return .peek // Already at minimum
        }
    }
    
    // Note: accessibilityDescription is defined in AccessibilityEnhancedBottomSheet.swift
}

// MARK: - Corner Radius Extension

extension View {
    /// Apply corner radius to specific corners
    /// - Parameters:
    ///   - radius: Corner radius
    ///   - corners: Which corners to apply radius to
    /// - Returns: Modified view with corner radius
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

/// Custom shape for rounded corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Animation Extension

extension Animation {
    /// Duration of the animation (approximation)
    var duration: TimeInterval {
        // Since SwiftUI Animation cases are not directly accessible,
        // we return a reasonable default duration
        return 0.4 // Default spring animation duration
    }
}

// MARK: - Preview

#Preview("Simple Bottom Sheet") {
    SimpleBottomSheetView(
        state: .constant(.peek),
        configuration: SimpleSheetConfiguration()
    ) {
        VStack {
            Text("Simple Bottom Sheet")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(0..<20) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                            .frame(height: 80)
                            .overlay(
                                Text("Facility \(index + 1)")
                                    .font(.headline)
                            )
                    }
                }
                .padding()
            }
        }
    }
}