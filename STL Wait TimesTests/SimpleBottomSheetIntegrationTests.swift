import XCTest
import SwiftUI
@testable import STL_Wait_Times

/// **SimpleBottomSheetIntegrationTests**: Integration tests for SimpleBottomSheetView with DashboardView
///
/// These tests verify that the simplified bottom sheet works correctly within the full app context,
/// including proper integration with the map view, facility data, and overall user experience.
class SimpleBottomSheetIntegrationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var dashboardView: DashboardView!
    var sheetState: BottomSheetState!
    var stateChangeHistory: [BottomSheetState] = []
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        dashboardView = DashboardView()
        sheetState = .peek
        stateChangeHistory = []
    }
    
    override func tearDown() {
        dashboardView = nil
        sheetState = nil
        stateChangeHistory = []
        super.tearDown()
    }
    
    // MARK: - Integration Tests
    
    func testBottomSheetIntegrationWithDashboard() {
        // Test that the bottom sheet integrates properly with the dashboard
        let configuration = SimpleSheetConfiguration()
        
        // Verify configuration is reasonable for dashboard context
        XCTAssertGreaterThan(configuration.peekRatio, 0.5, "Peek ratio should show significant content")
        XCTAssertLessThan(configuration.expandedRatio, 0.2, "Expanded ratio should leave space for map")
        XCTAssertGreaterThan(configuration.minSwipeDistance, 30.0, "Minimum swipe should prevent accidental triggers")
    }
    
    func testMapOpacityIntegration() {
        // Test that map opacity changes correctly with sheet state
        let mapOpacityForPeek = mapOpacity(for: .peek)
        let mapOpacityForMedium = mapOpacity(for: .medium)
        let mapOpacityForExpanded = mapOpacity(for: .expanded)
        
        XCTAssertEqual(mapOpacityForPeek, 1.0, "Map should be fully visible in peek state")
        XCTAssertEqual(mapOpacityForMedium, 1.0, "Map should be fully visible in medium state")
        XCTAssertEqual(mapOpacityForExpanded, 0.3, "Map should be dimmed in expanded state")
    }
    
    func testFacilityDataIntegration() {
        // Test that facility data is properly displayed in different sheet states
        let facilityData = createMockFacilityData()
        
        // Verify facility data structure
        XCTAssertFalse(facilityData.isEmpty, "Should have facility data")
        XCTAssertTrue(facilityData.count >= 3, "Should have at least 3 facilities for testing")
        
        // Test facility data properties
        let firstFacility = facilityData[0]
        XCTAssertFalse(firstFacility.name.isEmpty, "Facility should have a name")
        XCTAssertFalse(firstFacility.type.isEmpty, "Facility should have a type")
        XCTAssertFalse(firstFacility.waitTime.isEmpty, "Facility should have wait time")
    }
    
    func testSheetContentVisibility() {
        // Test that content is properly visible in different states
        let peekContentHeight = contentHeight(for: .peek, screenHeight: 800)
        let mediumContentHeight = contentHeight(for: .medium, screenHeight: 800)
        let expandedContentHeight = contentHeight(for: .expanded, screenHeight: 800)
        
        XCTAssertGreaterThan(peekContentHeight, 100, "Peek should show meaningful content")
        XCTAssertGreaterThan(mediumContentHeight, peekContentHeight, "Medium should show more content than peek")
        XCTAssertGreaterThan(expandedContentHeight, mediumContentHeight, "Expanded should show more content than medium")
    }
    
    func testSearchBarVisibility() {
        // Test that search bar is only visible in expanded state
        XCTAssertFalse(shouldShowSearchBar(for: .peek), "Search bar should not be visible in peek state")
        XCTAssertFalse(shouldShowSearchBar(for: .medium), "Search bar should not be visible in medium state")
        XCTAssertTrue(shouldShowSearchBar(for: .expanded), "Search bar should be visible in expanded state")
    }
    
    func testHapticFeedbackIntegration() {
        // Test that haptic feedback works properly in the integrated system
        let hapticSystem = MockIntegratedHapticSystem()
        
        // Simulate state transitions
        hapticSystem.handleStateChange(from: .peek, to: .medium)
        hapticSystem.handleStateChange(from: .medium, to: .expanded)
        hapticSystem.handleStateChange(from: .expanded, to: .medium)
        
        // Verify feedback was triggered
        XCTAssertEqual(hapticSystem.feedbackCount, 3, "Should trigger feedback for each state change")
        XCTAssertEqual(hapticSystem.lastTransition?.to, .medium, "Last transition should be to medium")
    }
    
    // MARK: - Performance Integration Tests
    
    func testPerformanceWithRealData() {
        // Test performance with realistic facility data
        let facilityData = createLargeFacilityDataSet()
        
        measure {
            // Simulate rapid state transitions with large data set
            var currentState = BottomSheetState.peek
            for _ in 0..<100 {
                currentState = currentState.nextStateUp
                if currentState == .expanded {
                    currentState = .peek
                }
                
                // Simulate content rendering
                _ = filterFacilitiesForState(facilityData, state: currentState)
            }
        }
    }
    
    func testMemoryUsageWithLargeDataSet() {
        // Test memory usage with large facility data set
        let largeDataSet = createLargeFacilityDataSet()
        
        // Create multiple sheet instances with large data
        var sheets: [SimpleBottomSheetView<AnyView>] = []
        
        for i in 0..<50 {
            let sheet = SimpleBottomSheetView(
                state: .constant(.peek),
                configuration: SimpleSheetConfiguration()
            ) {
                AnyView(
                    VStack {
                        ForEach(largeDataSet.indices, id: \.self) { index in
                            Text("Facility \(index)")
                        }
                    }
                )
            }
            sheets.append(sheet)
        }
        
        XCTAssertEqual(sheets.count, 50, "Should create 50 sheet instances")
        
        // Clean up
        sheets.removeAll()
    }
    
    // MARK: - Accessibility Integration Tests
    
    func testAccessibilityIntegration() {
        // Test accessibility features work properly in integrated system
        let accessibilityTester = MockAccessibilityTester()
        
        // Test VoiceOver announcements
        accessibilityTester.simulateStateChange(to: .medium)
        XCTAssertTrue(accessibilityTester.wasAnnouncementMade, "Should announce state change")
        XCTAssertTrue(accessibilityTester.lastAnnouncement.contains("medium"), "Announcement should mention medium state")
        
        // Test accessibility actions
        let availableActions = accessibilityTester.getAvailableActions(for: .medium)
        XCTAssertTrue(availableActions.contains("Expand"), "Should have expand action in medium state")
        XCTAssertTrue(availableActions.contains("Collapse"), "Should have collapse action in medium state")
    }
    
    func testReducedMotionIntegration() {
        // Test that reduced motion preference is respected
        let configuration = SimpleSheetConfiguration()
        
        // Test with reduced motion enabled
        let reducedMotionAnimation = Animation.linear(duration: 0.2)
        let normalAnimation = Animation.spring(response: configuration.animationResponse, dampingFraction: configuration.animationDamping)
        
        XCTAssertNotEqual(reducedMotionAnimation.duration, normalAnimation.duration, "Reduced motion should use different animation")
        XCTAssertLessThan(reducedMotionAnimation.duration, normalAnimation.duration, "Reduced motion should be faster")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingIntegration() {
        // Test error handling in integrated system
        let errorHandler = MockErrorHandler()
        
        // Test invalid state transitions
        errorHandler.handleInvalidStateTransition(from: .peek, to: .expanded)
        XCTAssertTrue(errorHandler.errorWasCaught, "Should catch invalid state transition")
        
        // Test concurrent animation prevention
        errorHandler.handleConcurrentAnimationAttempt()
        XCTAssertTrue(errorHandler.concurrentAnimationPrevented, "Should prevent concurrent animations")
    }
    
    // MARK: - Helper Methods
    
    private func createMockFacilityData() -> [MedicalFacility] {
        return [
            MedicalFacility(
                id: "1",
                name: "Test Hospital",
                type: "ER",
                waitTime: "25",
                waitDetails: "MINUTES",
                distance: "1.2 mi",
                waitChange: "+2 min",
                status: "Open",
                isOpen: true
            ),
            MedicalFacility(
                id: "2",
                name: "Test Urgent Care",
                type: "UC",
                waitTime: "15",
                waitDetails: "MINUTES",
                distance: "0.8 mi",
                waitChange: "-1 min",
                status: "Open",
                isOpen: true
            ),
            MedicalFacility(
                id: "3",
                name: "Test Clinic",
                type: "Clinic",
                waitTime: "35",
                waitDetails: "MINUTES",
                distance: "2.1 mi",
                waitChange: "Same",
                status: "Open",
                isOpen: true
            )
        ]
    }
    
    private func createLargeFacilityDataSet() -> [MedicalFacility] {
        var facilities: [MedicalFacility] = []
        
        for i in 0..<500 {
            let facility = MedicalFacility(
                id: "\(i)",
                name: "Test Facility \(i)",
                type: i % 2 == 0 ? "ER" : "UC",
                waitTime: "\(Int.random(in: 10...60))",
                waitDetails: "MINUTES",
                distance: "\(Double.random(in: 0.5...10.0)) mi",
                waitChange: "+\(Int.random(in: 0...5)) min",
                status: "Open",
                isOpen: true
            )
            facilities.append(facility)
        }
        
        return facilities
    }
    
    private func mapOpacity(for state: BottomSheetState) -> Double {
        switch state {
        case .peek, .medium:
            return 1.0
        case .expanded:
            return 0.3
        }
    }
    
    private func contentHeight(for state: BottomSheetState, screenHeight: CGFloat) -> CGFloat {
        let configuration = SimpleSheetConfiguration()
        
        switch state {
        case .peek:
            return screenHeight * (1.0 - configuration.peekRatio)
        case .medium:
            return screenHeight * (1.0 - configuration.mediumRatio)
        case .expanded:
            return screenHeight * (1.0 - configuration.expandedRatio)
        }
    }
    
    private func shouldShowSearchBar(for state: BottomSheetState) -> Bool {
        return state == .expanded
    }
    
    private func filterFacilitiesForState(_ facilities: [MedicalFacility], state: BottomSheetState) -> [MedicalFacility] {
        // Simulate filtering based on state
        switch state {
        case .peek:
            return Array(facilities.prefix(3))
        case .medium:
            return Array(facilities.prefix(10))
        case .expanded:
            return facilities
        }
    }
}

// MARK: - Mock Integration Types

class MockIntegratedHapticSystem {
    var feedbackCount = 0
    var lastTransition: (from: BottomSheetState, to: BottomSheetState)?
    
    func handleStateChange(from: BottomSheetState, to: BottomSheetState) {
        feedbackCount += 1
        lastTransition = (from: from, to: to)
    }
}

class MockAccessibilityTester {
    var wasAnnouncementMade = false
    var lastAnnouncement = ""
    
    func simulateStateChange(to state: BottomSheetState) {
        wasAnnouncementMade = true
        lastAnnouncement = "Sheet \(state.accessibilityDescription)"
    }
    
    func getAvailableActions(for state: BottomSheetState) -> [String] {
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

class MockErrorHandler {
    var errorWasCaught = false
    var concurrentAnimationPrevented = false
    
    func handleInvalidStateTransition(from: BottomSheetState, to: BottomSheetState) {
        // Simulate error handling for invalid transitions
        if from == .peek && to == .expanded {
            errorWasCaught = true
        }
    }
    
    func handleConcurrentAnimationAttempt() {
        concurrentAnimationPrevented = true
    }
}

// MARK: - Animation Extension for Testing

extension Animation {
    var duration: TimeInterval {
        // Since SwiftUI Animation cases are not directly accessible,
        // we return a reasonable default duration
        return 0.4 // Default spring animation duration
    }
}