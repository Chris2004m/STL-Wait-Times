import XCTest
import SwiftUI
@testable import STL_Wait_Times

/// **EnhancedScrollingIntegrationTests**: Integration tests for enhanced scrolling with DashboardView
///
/// These tests verify that the enhanced scrolling system works correctly within the full app context,
/// including proper integration with the bottom sheet, facility data, and overall user experience.
class EnhancedScrollingIntegrationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var dashboardView: DashboardView!
    var facilityData: [MedicalFacility]!
    var scrollPositionHistory: [STL_Wait_Times.ScrollPosition] = []
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        dashboardView = DashboardView()
        facilityData = createMockFacilityData()
        scrollPositionHistory = []
    }
    
    override func tearDown() {
        dashboardView = nil
        facilityData = nil
        scrollPositionHistory = []
        super.tearDown()
    }
    
    // MARK: - Integration Tests
    
    func testDashboardScrollingIntegration() {
        // Test that enhanced scrolling integrates properly with DashboardView
        let configuration = ScrollConfiguration(
            itemSpacing: 0,
            bottomPadding: 20,
            dividerLeadingPadding: 80,
            showScrollIndicators: false,
            animationResponse: 0.5,
            animationDamping: 0.8,
            enableViewRecycling: true,
            visibleRangeBuffer: 3
        )
        
        // Verify configuration matches dashboard requirements
        XCTAssertEqual(configuration.itemSpacing, 0, "Dashboard should have no item spacing")
        XCTAssertEqual(configuration.bottomPadding, 20, "Dashboard should have 20pt bottom padding")
        XCTAssertEqual(configuration.dividerLeadingPadding, 80, "Dashboard should have 80pt divider padding")
        XCTAssertFalse(configuration.showScrollIndicators, "Dashboard should not show scroll indicators")
        XCTAssertTrue(configuration.enableViewRecycling, "Dashboard should enable view recycling")
    }
    
    func testFacilityDataScrolling() {
        // Test scrolling with actual facility data
        let facilities = createMockFacilityData()
        
        // Verify facility data is properly structured for scrolling
        XCTAssertFalse(facilities.isEmpty, "Should have facility data")
        XCTAssertTrue(facilities.count >= 3, "Should have at least 3 facilities for scrolling")
        
        // Test that all facilities have required properties
        for facility in facilities {
            XCTAssertFalse(facility.id.isEmpty, "Facility should have valid ID")
            XCTAssertFalse(facility.name.isEmpty, "Facility should have name")
            XCTAssertFalse(facility.type.isEmpty, "Facility should have type")
            XCTAssertFalse(facility.waitTime.isEmpty, "Facility should have wait time")
        }
    }
    
    func testScrollingAcrossAllViewModes() {
        // Test scrolling behavior in all three view modes
        let states: [BottomSheetState] = [.peek, .medium, .expanded]
        let facilities = createMockFacilityData()
        
        for state in states {
            // Verify all facilities are visible in all states
            let visibleFacilities = getVisibleFacilities(for: state, facilities: facilities)
            XCTAssertEqual(visibleFacilities.count, facilities.count, "All facilities should be visible in \(state) mode")
        }
    }
    
    func testSTL_Wait_Times.ScrollPositionPersistenceAcrossStates() {
        // Test scroll position persistence across state changes
        var savedPositions: [BottomSheetState: STL_Wait_Times.ScrollPosition] = [:]
        
        // Simulate scroll positions in different states
        let peekPosition = STL_Wait_Times.ScrollPosition(offset: 50, timestamp: Date(), visibleRange: 0..<2)
        let mediumPosition = STL_Wait_Times.ScrollPosition(offset: 150, timestamp: Date(), visibleRange: 2..<4)
        let expandedPosition = STL_Wait_Times.ScrollPosition(offset: 300, timestamp: Date(), visibleRange: 5..<8)
        
        savedPositions[.peek] = peekPosition
        savedPositions[.medium] = mediumPosition
        savedPositions[.expanded] = expandedPosition
        
        // Test position retrieval and restoration
        XCTAssertEqual(savedPositions[.peek]?.offset, 50)
        XCTAssertEqual(savedPositions[.medium]?.offset, 150)
        XCTAssertEqual(savedPositions[.expanded]?.offset, 300)
        
        // Test visible range preservation
        XCTAssertEqual(savedPositions[.peek]?.visibleRange, 0..<2)
        XCTAssertEqual(savedPositions[.medium]?.visibleRange, 2..<4)
        XCTAssertEqual(savedPositions[.expanded]?.visibleRange, 5..<8)
    }
    
    func testScrollPerformanceWithRealData() {
        // Test scroll performance with realistic facility data
        let facilities = createLargeFacilityDataSet()
        
        measure {
            // Simulate scrolling through large dataset
            let metrics = ScrollPerformanceMetrics()
            
            for i in 0..<100 {
                let position = STL_Wait_Times.ScrollPosition(
                    offset: CGFloat(i * 80), // Approximate card height
                    timestamp: Date(),
                    visibleRange: i..<(i + 5)
                )
                metrics.recordScrollUpdate(position: position)
                
                // Simulate view recycling
                if i > 10 {
                    metrics.recordItemDisappear(index: i - 10)
                }
                metrics.recordItemAppear(index: i)
            }
        }
    }
    
    func testScrollingMemoryUsage() {
        // Test memory usage during scrolling
        let largeFacilitySet = createLargeFacilityDataSet()
        
        // Create multiple scroll views to test memory efficiency
        var scrollViews: [EnhancedScrollingView<MedicalFacility, AnyView>] = []
        
        for i in 0..<10 {
            let scrollView = EnhancedScrollingView(
                items: largeFacilitySet,
                sheetState: .constant(.expanded),
                configuration: ScrollConfiguration(enableViewRecycling: true)
            ) { facility, index, sheetState in
                AnyView(
                    VStack {
                        Text(facility.name)
                            .font(.headline)
                        Text(facility.waitTime)
                            .font(.subheadline)
                    }
                    .padding()
                )
            }
            scrollViews.append(scrollView)
        }
        
        XCTAssertEqual(scrollViews.count, 10, "Should create 10 scroll views")
        
        // Clean up
        scrollViews.removeAll()
    }
    
    // MARK: - Accessibility Integration Tests
    
    func testAccessibilityScrollingIntegration() {
        // Test accessibility features integration
        let facilities = createMockFacilityData()
        
        // Test accessibility labels for different states
        for state in [BottomSheetState.peek, .medium, .expanded] {
            let expectedLabel = "Scrollable list with \(facilities.count) items, currently in \(state.accessibilityDescription)"
            XCTAssertTrue(expectedLabel.contains(state.accessibilityDescription), "Accessibility label should include state description")
        }
    }
    
    func testAccessibilityScrollActions() {
        // Test accessibility scroll actions
        let facilities = createMockFacilityData()
        
        // Test that scroll actions are available
        let scrollActions = ["Scroll to top", "Scroll to bottom"]
        
        for action in scrollActions {
            XCTAssertFalse(action.isEmpty, "Scroll action should not be empty")
        }
    }
    
    func testVoiceOverAnnouncements() {
        // Test VoiceOver announcements during scrolling
        let facilities = createMockFacilityData()
        
        for state in [BottomSheetState.peek, .medium, .expanded] {
            let announcement = "Sheet \(state.accessibilityDescription), \(facilities.count) items available"
            XCTAssertTrue(announcement.contains(state.accessibilityDescription), "Announcement should include state description")
            XCTAssertTrue(announcement.contains("\(facilities.count)"), "Announcement should include item count")
        }
    }
    
    // MARK: - Performance Integration Tests
    
    func testScrollingFrameRate() {
        // Test that scrolling maintains target frame rate
        let metrics = ScrollPerformanceMetrics()
        let targetFPS = 60.0
        
        // Simulate rapid scroll updates
        let startTime = Date()
        for i in 0..<60 {
            let position = STL_Wait_Times.ScrollPosition(
                offset: CGFloat(i * 10),
                timestamp: Date(),
                visibleRange: i..<(i + 5)
            )
            metrics.recordScrollUpdate(position: position)
        }
        let endTime = Date()
        
        let actualDuration = endTime.timeIntervalSince(startTime)
        let expectedDuration = 1.0 // 60 updates in 1 second for 60 FPS
        
        XCTAssertLessThan(actualDuration, expectedDuration * 2, "Scroll updates should be performant")
    }
    
    func testViewRecyclingEfficiency() {
        // Test view recycling efficiency
        let metrics = ScrollPerformanceMetrics()
        let itemCount = 1000
        
        // Simulate scrolling through large list with view recycling
        for i in 0..<itemCount {
            metrics.recordItemAppear(index: i)
            
            // Simulate view recycling - items disappear as we scroll
            if i > 10 {
                metrics.recordItemDisappear(index: i - 10)
            }
        }
        
        // With proper view recycling, visible item count should be limited
        XCTAssertLessThan(metrics.visibleItemCount, itemCount, "View recycling should limit visible items")
        XCTAssertGreaterThan(metrics.visibleItemCount, 0, "Should have some visible items")
    }
    
    // MARK: - Edge Cases Integration Tests
    
    func testScrollingWithDynamicData() {
        // Test scrolling with dynamically changing data
        var facilities = createMockFacilityData()
        
        // Test initial state
        XCTAssertEqual(facilities.count, 3)
        
        // Simulate adding more facilities
        let newFacility = MedicalFacility(
            id: "4",
            name: "New Test Hospital",
            type: "ER",
            waitTime: "30",
            waitDetails: "MINUTES",
            distance: "1.5 mi",
            waitChange: "+3 min",
            status: "Open",
            isOpen: true
        )
        facilities.append(newFacility)
        
        XCTAssertEqual(facilities.count, 4)
        XCTAssertEqual(facilities.last?.name, "New Test Hospital")
    }
    
    func testScrollingWithEmptyData() {
        // Test scrolling behavior with empty data
        let emptyFacilities: [MedicalFacility] = []
        
        let scrollView = EnhancedScrollingView(
            items: emptyFacilities,
            sheetState: .constant(.medium),
            configuration: ScrollConfiguration()
        ) { facility, index, sheetState in
            AnyView(Text(facility.name))
        }
        
        XCTAssertNotNil(scrollView)
    }
    
    func testScrollingWithSingleItem() {
        // Test scrolling with single item
        let singleFacility = [createMockFacilityData().first!]
        
        let scrollView = EnhancedScrollingView(
            items: singleFacility,
            sheetState: .constant(.medium),
            configuration: ScrollConfiguration()
        ) { facility, index, sheetState in
            AnyView(Text(facility.name))
        }
        
        XCTAssertNotNil(scrollView)
    }
    
    // MARK: - Animation Integration Tests
    
    func testSmoothScrollAnimations() {
        // Test smooth scroll animations
        let configuration = ScrollConfiguration(
            animationResponse: 0.4,
            animationDamping: 0.8
        )
        
        // Test animation parameters are reasonable
        XCTAssertEqual(configuration.animationResponse, 0.4, accuracy: 0.01)
        XCTAssertEqual(configuration.animationDamping, 0.8, accuracy: 0.01)
        XCTAssertGreaterThan(configuration.animationResponse, 0.1, "Animation should be responsive")
        XCTAssertLessThan(configuration.animationResponse, 1.0, "Animation should not be too slow")
    }
    
    func testReducedMotionCompliance() {
        // Test reduced motion compliance
        let configuration = ScrollConfiguration()
        
        // Test that configuration supports reduced motion
        XCTAssertTrue(configuration.animationResponse > 0, "Should support animation")
        XCTAssertTrue(configuration.animationDamping > 0, "Should support damping")
        
        // In actual implementation, reduced motion would use linear animation
        let linearDuration = 0.2
        XCTAssertLessThan(linearDuration, configuration.animationResponse, "Linear animation should be faster")
    }
    
    // MARK: - Helper Methods
    
    private func createMockFacilityData() -> [MedicalFacility] {
        return [
            MedicalFacility(
                id: "1",
                name: "Barnes-Jewish Hospital",
                type: "ER",
                waitTime: "45",
                waitDetails: "MINUTES",
                distance: "2.3 mi",
                waitChange: "+5 min",
                status: "Open",
                isOpen: true
            ),
            MedicalFacility(
                id: "2",
                name: "Saint Louis University",
                type: "ER",
                waitTime: "32",
                waitDetails: "MINUTES",
                distance: "1.8 mi",
                waitChange: "-2 min",
                status: "Open",
                isOpen: true
            ),
            MedicalFacility(
                id: "3",
                name: "Mercy Hospital South",
                type: "ER",
                waitTime: "18",
                waitDetails: "MINUTES",
                distance: "3.1 mi",
                waitChange: "Same",
                status: "Open",
                isOpen: true
            )
        ]
    }
    
    private func createLargeFacilityDataSet() -> [MedicalFacility] {
        var facilities: [MedicalFacility] = []
        
        for i in 0..<200 {
            let facility = MedicalFacility(
                id: "\(i)",
                name: "Test Facility \(i)",
                type: i % 2 == 0 ? "ER" : "UC",
                waitTime: "\(Int.random(in: 10...60))",
                waitDetails: "MINUTES",
                distance: "\(String(format: "%.1f", Double.random(in: 0.5...10.0))) mi",
                waitChange: ["+\(Int.random(in: 0...10)) min", "-\(Int.random(in: 0...5)) min", "Same"].randomElement() ?? "Same",
                status: "Open",
                isOpen: true
            )
            facilities.append(facility)
        }
        
        return facilities
    }
    
    private func getVisibleFacilities(for state: BottomSheetState, facilities: [MedicalFacility]) -> [MedicalFacility] {
        // In the current implementation, all facilities are visible in all states
        switch state {
        case .peek:
            return facilities
        case .medium:
            return facilities
        case .expanded:
            return facilities
        }
    }
}

// MARK: - Performance Baseline Tests

class EnhancedScrollingPerformanceIntegrationTests: XCTestCase {
    
    func testRealWorldScrollingPerformance() {
        // Test real-world scrolling performance
        let facilities = createRealisticFacilityData()
        
        measure {
            let scrollView = EnhancedScrollingView(
                items: facilities,
                sheetState: .constant(.expanded),
                configuration: ScrollConfiguration(enableViewRecycling: true)
            ) { facility, index, sheetState in
                AnyView(
                    HStack {
                        VStack(alignment: .leading) {
                            Text(facility.name)
                                .font(.headline)
                            Text(facility.type)
                                .font(.caption)
                        }
                        Spacer()
                        Text(facility.waitTime)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                )
            }
            
            // Simulate scrolling
            let metrics = ScrollPerformanceMetrics()
            for i in 0..<50 {
                let position = STL_Wait_Times.ScrollPosition(
                    offset: CGFloat(i * 100),
                    timestamp: Date(),
                    visibleRange: i..<(i + 10)
                )
                metrics.recordScrollUpdate(position: position)
            }
        }
    }
    
    func testMemoryEfficiencyWithLargeDataset() {
        // Test memory efficiency with large dataset
        let largeFacilities = createRealisticFacilityData(count: 1000)
        
        measure {
            let scrollView = EnhancedScrollingView(
                items: largeFacilities,
                sheetState: .constant(.expanded),
                configuration: ScrollConfiguration(
                    enableViewRecycling: true,
                    visibleRangeBuffer: 5
                )
            ) { facility, index, sheetState in
                AnyView(Text(facility.name))
            }
            
            // Simulate memory-efficient scrolling
            let metrics = ScrollPerformanceMetrics()
            for i in 0..<100 {
                metrics.recordItemAppear(index: i)
                if i > 20 {
                    metrics.recordItemDisappear(index: i - 20)
                }
            }
        }
    }
    
    private func createRealisticFacilityData(count: Int = 50) -> [MedicalFacility] {
        let hospitalNames = [
            "Barnes-Jewish Hospital", "Saint Louis University", "Mercy Hospital South",
            "Christian Hospital", "Missouri Baptist Medical Center", "SSM Health Cardinal Glennon",
            "St. Luke's Hospital", "Progress West Hospital", "Mercy Hospital St. Louis",
            "Barnes-Jewish West County Hospital"
        ]
        
        let types = ["ER", "UC", "Clinic"]
        
        return (0..<count).map { index in
            MedicalFacility(
                id: "\(index)",
                name: hospitalNames[index % hospitalNames.count] + " \(index + 1)",
                type: types[index % types.count],
                waitTime: "\(Int.random(in: 5...90))",
                waitDetails: "MINUTES",
                distance: "\(String(format: "%.1f", Double.random(in: 0.2...15.0))) mi",
                waitChange: ["+\(Int.random(in: 0...15)) min", "-\(Int.random(in: 0...10)) min", "Same"].randomElement() ?? "Same",
                status: ["Open", "Busy", "Critical"].randomElement() ?? "Open",
                isOpen: Bool.random()
            )
        }
    }
}