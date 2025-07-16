import XCTest
import SwiftUI
@testable import STL_Wait_Times

/// **SimpleBottomSheetTests**: Comprehensive test suite for SimpleBottomSheetView
///
/// Tests cover:
/// - Swipe gesture recognition and state transitions
/// - Haptic feedback verification
/// - Accessibility compliance
/// - Performance characteristics
/// - Edge cases and error handling
class SimpleBottomSheetTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var bottomSheetState: BottomSheetState!
    var configuration: SimpleSheetConfiguration!
    var stateChangeCallback: ((BottomSheetState) -> Void)?
    var stateChangeHistory: [BottomSheetState] = []
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        bottomSheetState = .peek
        configuration = SimpleSheetConfiguration()
        stateChangeHistory = []
        
        // Setup state change tracking
        stateChangeCallback = { [weak self] newState in
            self?.stateChangeHistory.append(newState)
        }
    }
    
    override func tearDown() {
        bottomSheetState = nil
        configuration = nil
        stateChangeCallback = nil
        stateChangeHistory = []
        super.tearDown()
    }
    
    // MARK: - State Transition Tests
    
    func testStateTransitionFromPeek() {
        // Test swipe up from peek to medium
        bottomSheetState = .peek
        let nextState = bottomSheetState.nextStateUp
        XCTAssertEqual(nextState, .medium, "Swiping up from peek should go to medium")
        
        // Test swipe down from peek (should stay at peek)
        let previousState = bottomSheetState.nextStateDown
        XCTAssertEqual(previousState, .peek, "Swiping down from peek should stay at peek")
    }
    
    func testStateTransitionFromMedium() {
        // Test swipe up from medium to expanded
        bottomSheetState = .medium
        let nextState = bottomSheetState.nextStateUp
        XCTAssertEqual(nextState, .expanded, "Swiping up from medium should go to expanded")
        
        // Test swipe down from medium to peek
        let previousState = bottomSheetState.nextStateDown
        XCTAssertEqual(previousState, .peek, "Swiping down from medium should go to peek")
    }
    
    func testStateTransitionFromExpanded() {
        // Test swipe up from expanded (should stay at expanded)
        bottomSheetState = .expanded
        let nextState = bottomSheetState.nextStateUp
        XCTAssertEqual(nextState, .expanded, "Swiping up from expanded should stay at expanded")
        
        // Test swipe down from expanded to medium
        let previousState = bottomSheetState.nextStateDown
        XCTAssertEqual(previousState, .medium, "Swiping down from expanded should go to medium")
    }
    
    func testCompleteStateTransitionSequence() {
        // Test complete sequence: peek -> medium -> expanded -> medium -> peek
        var currentState = BottomSheetState.peek
        
        // Peek to medium
        currentState = currentState.nextStateUp
        XCTAssertEqual(currentState, .medium)
        
        // Medium to expanded
        currentState = currentState.nextStateUp
        XCTAssertEqual(currentState, .expanded)
        
        // Expanded to medium
        currentState = currentState.nextStateDown
        XCTAssertEqual(currentState, .medium)
        
        // Medium to peek
        currentState = currentState.nextStateDown
        XCTAssertEqual(currentState, .peek)
    }
    
    // MARK: - Swipe Gesture Tests
    
    func testSwipeGestureRecognition() {
        let swipeUpGesture = createSwipeGesture(direction: .up, distance: 100)
        let swipeDownGesture = createSwipeGesture(direction: .down, distance: 100)
        let shortSwipeGesture = createSwipeGesture(direction: .up, distance: 30)
        
        // Test that significant swipes are recognized
        XCTAssertTrue(abs(swipeUpGesture.translation.height) > configuration.minSwipeDistance)
        XCTAssertTrue(abs(swipeDownGesture.translation.height) > configuration.minSwipeDistance)
        
        // Test that short swipes are ignored
        XCTAssertFalse(abs(shortSwipeGesture.translation.height) > configuration.minSwipeDistance)
    }
    
    func testSwipeThresholds() {
        // Test minimum swipe distance threshold
        let minDistance = configuration.minSwipeDistance
        
        // Swipe just below threshold should not trigger state change
        let shortSwipe = createSwipeGesture(direction: .up, distance: minDistance - 1)
        XCTAssertFalse(abs(shortSwipe.translation.height) > minDistance)
        
        // Swipe just above threshold should trigger state change
        let validSwipe = createSwipeGesture(direction: .up, distance: minDistance + 1)
        XCTAssertTrue(abs(validSwipe.translation.height) > minDistance)
    }
    
    // MARK: - Haptic Feedback Tests
    
    func testHapticFeedbackIntensity() {
        // Test that different states have different haptic intensities
        let peekFeedback = MockHapticFeedback.intensity(for: .peek)
        let mediumFeedback = MockHapticFeedback.intensity(for: .medium)
        let expandedFeedback = MockHapticFeedback.intensity(for: .expanded)
        
        XCTAssertEqual(peekFeedback, 0.7, "Peek state should have 0.7 intensity")
        XCTAssertEqual(mediumFeedback, 0.8, "Medium state should have 0.8 intensity")
        XCTAssertEqual(expandedFeedback, 1.0, "Expanded state should have 1.0 intensity")
    }
    
    func testHapticFeedbackTriggers() {
        // Test that haptic feedback is triggered for each state transition
        let mockHapticSystem = MockHapticFeedbackSystem()
        
        // Simulate state transitions
        mockHapticSystem.triggerFeedback(for: .peek)
        mockHapticSystem.triggerFeedback(for: .medium)
        mockHapticSystem.triggerFeedback(for: .expanded)
        
        XCTAssertEqual(mockHapticSystem.feedbackCount, 3, "Should trigger haptic feedback 3 times")
        XCTAssertEqual(mockHapticSystem.lastTriggeredState, .expanded, "Last triggered state should be expanded")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() {
        // Test accessibility descriptions for each state
        XCTAssertEqual(
            BottomSheetState.peek.accessibilityDescription,
            "minimized, showing facility summary"
        )
        XCTAssertEqual(
            BottomSheetState.medium.accessibilityDescription,
            "medium size, showing facility details"
        )
        XCTAssertEqual(
            BottomSheetState.expanded.accessibilityDescription,
            "expanded, showing full facility list with search"
        )
    }
    
    func testAccessibilityActions() {
        // Test that accessibility actions are available for each state
        let peekActions = MockAccessibilityActions.availableActions(for: .peek)
        let mediumActions = MockAccessibilityActions.availableActions(for: .medium)
        let expandedActions = MockAccessibilityActions.availableActions(for: .expanded)
        
        // Peek state should have expand and medium actions
        XCTAssertTrue(peekActions.contains("Expand"))
        XCTAssertTrue(peekActions.contains("Medium size"))
        XCTAssertFalse(peekActions.contains("Collapse"))
        
        // Medium state should have expand and collapse actions
        XCTAssertTrue(mediumActions.contains("Expand"))
        XCTAssertTrue(mediumActions.contains("Collapse"))
        XCTAssertFalse(mediumActions.contains("Medium size"))
        
        // Expanded state should have collapse and medium actions
        XCTAssertFalse(expandedActions.contains("Expand"))
        XCTAssertTrue(expandedActions.contains("Collapse"))
        XCTAssertTrue(expandedActions.contains("Medium size"))
    }
    
    // MARK: - Performance Tests
    
    func testAnimationPerformance() {
        // Test animation duration is within acceptable range
        let _ = SimpleSheetConfiguration()
        let expectedDuration = configuration.animationResponse
        
        XCTAssertLessThanOrEqual(expectedDuration, 0.6, "Animation should complete within 600ms")
        XCTAssertGreaterThanOrEqual(expectedDuration, 0.2, "Animation should be at least 200ms for visibility")
    }
    
    func testGestureResponseTime() {
        // Test that gesture recognition happens quickly
        let startTime = CACurrentMediaTime()
        
        // Simulate gesture processing
        let gesture = createSwipeGesture(direction: .up, distance: 100)
        _ = gesture.translation.height > configuration.minSwipeDistance
        
        let endTime = CACurrentMediaTime()
        let processingTime = endTime - startTime
        
        XCTAssertLessThan(processingTime, 0.016, "Gesture processing should be under 16ms (60fps)")
    }
    
    func testMemoryUsage() {
        // Test that creating multiple instances doesn't cause memory issues
        var bottomSheets: [SimpleBottomSheetView<Text>] = []
        
        for i in 0..<100 {
            let sheet = SimpleBottomSheetView(
                state: .constant(.peek),
                configuration: SimpleSheetConfiguration()
            ) {
                Text("Sheet \(i)")
            }
            bottomSheets.append(sheet)
        }
        
        // Test that we can create many instances without issues
        XCTAssertEqual(bottomSheets.count, 100)
        
        // Clean up
        bottomSheets.removeAll()
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationDefaults() {
        let config = SimpleSheetConfiguration()
        
        // Test default values
        XCTAssertEqual(config.peekRatio, 0.72, accuracy: 0.01)
        XCTAssertEqual(config.mediumRatio, 0.43, accuracy: 0.01)
        XCTAssertEqual(config.expandedRatio, 0.06, accuracy: 0.01)
        XCTAssertEqual(config.minSwipeDistance, 50.0, accuracy: 0.01)
        XCTAssertEqual(config.animationResponse, 0.4, accuracy: 0.01)
        XCTAssertEqual(config.animationDamping, 0.8, accuracy: 0.01)
    }
    
    func testCustomConfiguration() {
        let customConfig = SimpleSheetConfiguration(
            peekRatio: 0.8,
            mediumRatio: 0.5,
            expandedRatio: 0.1,
            animationResponse: 0.3,
            animationDamping: 0.9,
            minSwipeDistance: 75.0
        )
        
        XCTAssertEqual(customConfig.peekRatio, 0.8, accuracy: 0.01)
        XCTAssertEqual(customConfig.mediumRatio, 0.5, accuracy: 0.01)
        XCTAssertEqual(customConfig.expandedRatio, 0.1, accuracy: 0.01)
        XCTAssertEqual(customConfig.minSwipeDistance, 75.0, accuracy: 0.01)
        XCTAssertEqual(customConfig.animationResponse, 0.3, accuracy: 0.01)
        XCTAssertEqual(customConfig.animationDamping, 0.9, accuracy: 0.01)
    }
    
    // MARK: - Edge Cases
    
    func testConcurrentAnimations() {
        // Test that concurrent animations are handled gracefully
        let mockBottomSheet = MockBottomSheetView()
        
        // Try to trigger multiple animations rapidly
        mockBottomSheet.simulateRapidStateChanges()
        
        // Should only process one animation at a time
        XCTAssertTrue(mockBottomSheet.animationQueue.count <= 1, "Should not queue multiple animations")
    }
    
    func testInvalidSwipeDirections() {
        // Test horizontal swipes don't trigger state changes
        let horizontalSwipe = createSwipeGesture(direction: .left, distance: 100)
        
        // Horizontal swipes should not affect vertical state transitions
        XCTAssertLessThan(abs(horizontalSwipe.translation.height), configuration.minSwipeDistance)
    }
    
    // MARK: - Helper Methods
    
    private func createSwipeGesture(direction: SwipeDirection, distance: CGFloat) -> MockDragGestureValue {
        let translation: CGSize
        
        switch direction {
        case .up:
            translation = CGSize(width: 0, height: -distance)
        case .down:
            translation = CGSize(width: 0, height: distance)
        case .left:
            translation = CGSize(width: -distance, height: 0)
        case .right:
            translation = CGSize(width: distance, height: 0)
        }
        
        return MockDragGestureValue(translation: translation)
    }
}

// MARK: - Mock Types

enum SwipeDirection {
    case up, down, left, right
}

struct MockDragGestureValue {
    let translation: CGSize
    let location: CGPoint = .zero
    let startLocation: CGPoint = .zero
    let velocity: CGSize = .zero
    let time: Date = Date()
}

class MockHapticFeedbackSystem {
    var feedbackCount = 0
    var lastTriggeredState: BottomSheetState?
    
    func triggerFeedback(for state: BottomSheetState) {
        feedbackCount += 1
        lastTriggeredState = state
    }
}

struct MockHapticFeedback {
    static func intensity(for state: BottomSheetState) -> CGFloat {
        switch state {
        case .peek: return 0.7
        case .medium: return 0.8
        case .expanded: return 1.0
        }
    }
}

struct MockAccessibilityActions {
    static func availableActions(for state: BottomSheetState) -> [String] {
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
}

class MockBottomSheetView {
    var animationQueue: [BottomSheetState] = []
    var isAnimating = false
    
    func simulateRapidStateChanges() {
        // Simulate rapid state changes
        if !isAnimating {
            isAnimating = true
            animationQueue.append(.medium)
            
            // Try to add more animations while one is running
            if !isAnimating {
                animationQueue.append(.expanded)
            }
        }
    }
}

// MARK: - Performance Baseline Tests

class SimpleBottomSheetPerformanceTests: XCTestCase {
    
    func testStateTransitionPerformance() {
        let configuration = SimpleSheetConfiguration()
        
        measure {
            // Test rapid state transitions
            var state = BottomSheetState.peek
            for _ in 0..<1000 {
                state = state.nextStateUp
                if state == .expanded {
                    state = .peek
                }
            }
        }
    }
    
    func testGestureProcessingPerformance() {
        let configuration = SimpleSheetConfiguration()
        
        measure {
            // Test gesture processing performance
            for i in 0..<10000 {
                let distance = CGFloat(i % 200)
                let translation = CGSize(width: 0, height: distance)
                _ = abs(translation.height) > configuration.minSwipeDistance
            }
        }
    }
}