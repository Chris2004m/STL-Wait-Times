import SwiftUI
import UIKit

/// **UltimateBottomSheetView**: Ultra-smooth bottom sheet with physics-based animations
///
/// Features:
/// - Continuous gesture tracking with momentum
/// - Elastic resistance at boundaries
/// - Fluid physics-based animations
/// - Optimized performance with gesture prediction
/// - Advanced accessibility support
/// - Seamless state transitions
struct UltimateBottomSheetView<Content: View>: View {
    
    // MARK: - Public Properties
    
    /// Current sheet state
    @Binding var state: BottomSheetState
    
    /// Content to display in the sheet
    let content: Content
    
    /// Callback when state changes
    var onStateChange: ((BottomSheetState) -> Void)?
    
    /// Configuration for sheet behavior
    let configuration: SheetConfiguration
    
    // MARK: - Private State
    
    /// Current drag translation
    @State private var dragTranslation: CGFloat = 0
    
    /// Drag velocity for momentum calculation
    @State private var dragVelocity: CGFloat = 0
    
    /// Previous drag position for velocity calculation
    @State private var previousDragPosition: CGFloat = 0
    
    /// Timestamp of last drag update
    @State private var lastDragTime: Date = Date()
    
    /// Whether user is actively dragging
    @State private var isDragging: Bool = false
    
    /// Target position for current state
    @State private var targetPosition: CGFloat = 0
    
    /// Animation progress (0-1)
    @State private var animationProgress: CGFloat = 0
    
    /// Haptic feedback generator
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    /// Performance metrics
    @State private var frameRate: Double = 60.0
    @State private var lastFrameTime: CFTimeInterval = 0
    
    // MARK: - Initialization
    
    init(
        state: Binding<BottomSheetState>,
        configuration: SheetConfiguration = SheetConfiguration(),
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
                // Background overlay
                backgroundOverlay(geometry: geometry)
                
                // Main sheet content
                sheetContent(geometry: geometry)
                    .animation(.none, value: isDragging) // No animation during drag
                    .offset(y: currentOffset(geometry: geometry))
                    .gesture(
                        DragGesture(coordinateSpace: .global)
                            .onChanged { value in
                                handleDragChanged(value: value, geometry: geometry)
                            }
                            .onEnded { value in
                                handleDragEnded(value: value, geometry: geometry)
                            }
                    )
            }
        }
        .onAppear {
            setupInitialState()
        }
        .onChange(of: state) { _, newState in
            animateToState(newState)
        }
    }
    
    // MARK: - Sheet Content
    
    @ViewBuilder
    private func sheetContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Drag handle
            dragHandle
                .padding(.top, configuration.handlePadding)
                .background(Color.clear)
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { value in
                            handleDragChanged(value: value, geometry: geometry)
                        }
                        .onEnded { value in
                            handleDragEnded(value: value, geometry: geometry)
                        }
                )
            
            // Content
            content
                .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: configuration.cornerRadius)
                .fill(configuration.backgroundColor)
                .shadow(
                    color: .black.opacity(shadowOpacity),
                    radius: configuration.shadowRadius,
                    x: 0,
                    y: -configuration.shadowRadius / 2
                )
        )
        .clipShape(
            RoundedRectangle(cornerRadius: configuration.cornerRadius)
        )
    }
    
    // MARK: - Drag Handle
    
    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: configuration.handleHeight / 2)
            .fill(configuration.handleColor)
            .frame(
                width: configuration.handleWidth,
                height: configuration.handleHeight
            )
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
    }
    
    // MARK: - Background Overlay
    
    @ViewBuilder
    private func backgroundOverlay(geometry: GeometryProxy) -> some View {
        Color.black
            .opacity(backgroundOpacity(geometry: geometry))
            .ignoresSafeArea()
            .onTapGesture {
                if state != .peek {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        state = .peek
                    }
                }
            }
    }
    
    // MARK: - Calculations
    
    /// Calculate current offset based on state and drag
    private func currentOffset(geometry: GeometryProxy) -> CGFloat {
        let baseOffset = offsetForState(state, geometry: geometry)
        let resistance = calculateResistance(for: dragTranslation, geometry: geometry)
        return baseOffset + resistance
    }
    
    /// Calculate offset for a given state
    private func offsetForState(_ state: BottomSheetState, geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height
        
        switch state {
        case .peek:
            return height * configuration.peekRatio
        case .medium:
            return height * configuration.mediumRatio
        case .expanded:
            return height * configuration.expandedRatio
        }
    }
    
    /// Calculate elastic resistance for out-of-bounds dragging
    private func calculateResistance(for translation: CGFloat, geometry: GeometryProxy) -> CGFloat {
        let baseOffset = offsetForState(state, geometry: geometry)
        let proposedOffset = baseOffset + translation
        
        let minOffset = offsetForState(.expanded, geometry: geometry)
        let maxOffset = offsetForState(.peek, geometry: geometry)
        
        if proposedOffset < minOffset {
            // Dragging past expanded state
            let excess = minOffset - proposedOffset
            return translation - excess + (excess * configuration.elasticResistance)
        } else if proposedOffset > maxOffset {
            // Dragging past peek state
            let excess = proposedOffset - maxOffset
            return translation - excess + (excess * configuration.elasticResistance)
        }
        
        return translation
    }
    
    /// Calculate background opacity based on sheet position
    private func backgroundOpacity(geometry: GeometryProxy) -> Double {
        let currentPos = currentOffset(geometry: geometry)
        let peekPos = offsetForState(.peek, geometry: geometry)
        let expandedPos = offsetForState(.expanded, geometry: geometry)
        
        let progress = 1.0 - (currentPos - expandedPos) / (peekPos - expandedPos)
        return min(max(progress * configuration.maxBackgroundOpacity, 0), configuration.maxBackgroundOpacity)
    }
    
    /// Calculate shadow opacity based on state
    private var shadowOpacity: Double {
        switch state {
        case .peek:
            return 0.1
        case .medium:
            return 0.2
        case .expanded:
            return 0.3
        }
    }
    
    // MARK: - Gesture Handling
    
    /// Handle drag gesture changes
    private func handleDragChanged(value: DragGesture.Value, geometry: GeometryProxy) {
        if !isDragging {
            isDragging = true
            hapticFeedback.prepare()
            previousDragPosition = value.translation.height
            lastDragTime = Date()
        }
        
        // Calculate velocity
        let currentTime = Date()
        let deltaTime = currentTime.timeIntervalSince(lastDragTime)
        let deltaPosition = value.translation.height - previousDragPosition
        
        if deltaTime > 0 {
            dragVelocity = deltaPosition / deltaTime
        }
        
        dragTranslation = value.translation.height
        previousDragPosition = value.translation.height
        lastDragTime = currentTime
        
        // Performance monitoring
        updateFrameRate()
    }
    
    /// Handle drag gesture end
    private func handleDragEnded(value: DragGesture.Value, geometry: GeometryProxy) {
        isDragging = false
        
        let finalState = calculateFinalState(
            translation: value.translation.height,
            velocity: dragVelocity,
            geometry: geometry
        )
        
        // Animate to final state
        animateToState(finalState, withVelocity: dragVelocity)
        
        // Reset drag state
        dragTranslation = 0
        dragVelocity = 0
        
        // Haptic feedback if state changed
        if finalState != state {
            hapticFeedback.impactOccurred()
        }
    }
    
    /// Calculate final state based on drag and velocity
    private func calculateFinalState(
        translation: CGFloat,
        velocity: CGFloat,
        geometry: GeometryProxy
    ) -> BottomSheetState {
        let currentPos = currentOffset(geometry: geometry)
        let peekPos = offsetForState(.peek, geometry: geometry)
        let mediumPos = offsetForState(.medium, geometry: geometry)
        let expandedPos = offsetForState(.expanded, geometry: geometry)
        
        // Strong velocity overrides position
        if abs(velocity) > configuration.velocityThreshold {
            if velocity > 0 {
                // Fast downward swipe
                return state == .expanded ? .medium : .peek
            } else {
                // Fast upward swipe
                return state == .peek ? .medium : .expanded
            }
        }
        
        // Position-based determination
        let peekDistance = abs(currentPos - peekPos)
        let mediumDistance = abs(currentPos - mediumPos)
        let expandedDistance = abs(currentPos - expandedPos)
        
        if peekDistance <= mediumDistance && peekDistance <= expandedDistance {
            return .peek
        } else if mediumDistance <= expandedDistance {
            return .medium
        } else {
            return .expanded
        }
    }
    
    // MARK: - Animation
    
    /// Animate to a specific state
    private func animateToState(_ targetState: BottomSheetState, withVelocity velocity: CGFloat = 0) {
        let animation = createSpringAnimation(withVelocity: velocity)
        
        withAnimation(animation) {
            state = targetState
        }
        
        // Callback notification
        onStateChange?(targetState)
        
        // Accessibility announcement
        announceStateChange(targetState)
    }
    
    /// Create spring animation with velocity
    private func createSpringAnimation(withVelocity velocity: CGFloat) -> Animation {
        let response = configuration.springResponse
        let damping = configuration.springDamping
        
        // Adjust animation based on velocity
        let adjustedResponse = max(response * (1.0 - abs(velocity) / 2000.0), 0.2)
        let adjustedDamping = min(damping * (1.0 + abs(velocity) / 5000.0), 0.9)
        
        return .spring(response: adjustedResponse, dampingFraction: adjustedDamping)
    }
    
    // MARK: - Setup and Utilities
    
    /// Setup initial state
    private func setupInitialState() {
        hapticFeedback.prepare()
        targetPosition = 0
        animationProgress = 0
    }
    
    /// Update frame rate monitoring
    private func updateFrameRate() {
        let currentTime = CACurrentMediaTime()
        if lastFrameTime > 0 {
            let deltaTime = currentTime - lastFrameTime
            frameRate = 1.0 / deltaTime
        }
        lastFrameTime = currentTime
    }
    
    /// Announce state change for accessibility
    private func announceStateChange(_ newState: BottomSheetState) {
        let announcement = "Sheet \(newState.displayName)"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}

// MARK: - Configuration

/// Configuration for sheet behavior and appearance
struct SheetConfiguration {
    // Position ratios (0 = top, 1 = bottom)
    let peekRatio: CGFloat
    let mediumRatio: CGFloat
    let expandedRatio: CGFloat
    
    // Animation parameters
    let springResponse: CGFloat
    let springDamping: CGFloat
    let velocityThreshold: CGFloat
    let elasticResistance: CGFloat
    
    // Appearance
    let cornerRadius: CGFloat
    let backgroundColor: Color
    let shadowRadius: CGFloat
    let maxBackgroundOpacity: Double
    
    // Handle
    let handleWidth: CGFloat
    let handleHeight: CGFloat
    let handleColor: Color
    let handlePadding: CGFloat
    
    init(
        peekRatio: CGFloat = 0.72,
        mediumRatio: CGFloat = 0.43,
        expandedRatio: CGFloat = 0.06,
        springResponse: CGFloat = 0.4,
        springDamping: CGFloat = 0.8,
        velocityThreshold: CGFloat = 1000.0,
        elasticResistance: CGFloat = 0.3,
        cornerRadius: CGFloat = 20,
        backgroundColor: Color = Color(.systemBackground),
        shadowRadius: CGFloat = 10,
        maxBackgroundOpacity: Double = 0.3,
        handleWidth: CGFloat = 40,
        handleHeight: CGFloat = 5,
        handleColor: Color = Color(.systemGray4),
        handlePadding: CGFloat = 10
    ) {
        self.peekRatio = peekRatio
        self.mediumRatio = mediumRatio
        self.expandedRatio = expandedRatio
        self.springResponse = springResponse
        self.springDamping = springDamping
        self.velocityThreshold = velocityThreshold
        self.elasticResistance = elasticResistance
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.shadowRadius = shadowRadius
        self.maxBackgroundOpacity = maxBackgroundOpacity
        self.handleWidth = handleWidth
        self.handleHeight = handleHeight
        self.handleColor = handleColor
        self.handlePadding = handlePadding
    }
}

// MARK: - Enhanced Bottom Sheet State

extension BottomSheetState {
    /// Progress value between states (0-1)
    var progressValue: CGFloat {
        switch self {
        case .peek: return 0.0
        case .medium: return 0.5
        case .expanded: return 1.0
        }
    }
    
    // Note: nextStateUp and nextStateDown are defined in SimpleBottomSheetView.swift
    // Note: accessibilityDescription is defined in AccessibilityEnhancedBottomSheet.swift
}

// MARK: - Preview

#Preview("Ultimate Bottom Sheet") {
    UltimateBottomSheetView(
        state: .constant(.peek),
        configuration: SheetConfiguration()
    ) {
        VStack {
            Text("Ultra-Smooth Bottom Sheet")
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
                                Text("Item \(index + 1)")
                                    .font(.headline)
                            )
                    }
                }
                .padding()
            }
        }
    }
}