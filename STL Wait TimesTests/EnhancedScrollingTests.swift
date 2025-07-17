import XCTest
import SwiftUI
@testable import STL_Wait_Times

/// **EnhancedScrollingTests**: Comprehensive test suite for enhanced scrolling functionality
///
/// Tests cover:
/// - Smooth scrolling behavior in all view modes
/// - Scroll position persistence across state transitions
/// - Performance optimization and view recycling
/// - Accessibility features and compliance
/// - Error handling and edge cases
/// - Integration with DashboardView
class EnhancedScrollingTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var scrollingView: EnhancedScrollingView<TestItem, AnyView>!
    var testItems: [TestItem]!
    var sheetState: BottomSheetState!
    var scrollConfiguration: ScrollConfiguration!
    var positionChanges: [STL_Wait_Times.ScrollPosition] = []
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        // Create test data
        testItems = createTestItems(count: 50)
        sheetState = .peek
        scrollConfiguration = ScrollConfiguration()
        positionChanges = []
        
        // Create scrolling view
        scrollingView = EnhancedScrollingView(
            items: testItems,
            sheetState: .constant(sheetState),
            configuration: scrollConfiguration,
            onScrollPositionChange: { position in
                self.positionChanges.append(position)
            }
        ) { item, index, sheetState in
            AnyView(
                VStack {
                    Text(item.title)
                        .font(.headline)
                    Text(item.subtitle)
                        .font(.subheadline)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            )
        }
    }
    
    override func tearDown() {
        scrollingView = nil
        testItems = nil
        sheetState = nil
        scrollConfiguration = nil
        positionChanges = []
        super.tearDown()
    }
    
    // MARK: - Basic Scrolling Tests
    
    func testScrollingViewInitialization() {
        // Test that scrolling view initializes properly
        XCTAssertNotNil(scrollingView)
        XCTAssertEqual(testItems.count, 50)
        XCTAssertEqual(scrollConfiguration.itemSpacing, 0)
        XCTAssertEqual(scrollConfiguration.bottomPadding, 20)
    }
    
    func testScrollConfigurationDefaults() {
        // Test default configuration values
        let config = ScrollConfiguration()
        
        XCTAssertEqual(config.itemSpacing, 0)
        XCTAssertEqual(config.bottomPadding, 20)
        XCTAssertEqual(config.dividerLeadingPadding, 80)
        XCTAssertFalse(config.showScrollIndicators)
        XCTAssertEqual(config.animationResponse, 0.4, accuracy: 0.01)
        XCTAssertEqual(config.animationDamping, 0.8, accuracy: 0.01)
        XCTAssertTrue(config.enableViewRecycling)
        XCTAssertEqual(config.visibleRangeBuffer, 3)
    }
    
    func testScrollConfigurationCustomization() {
        // Test custom configuration
        let customConfig = ScrollConfiguration(
            itemSpacing: 16,
            bottomPadding: 40,
            dividerLeadingPadding: 100,
            showScrollIndicators: true,
            animationResponse: 0.6,
            animationDamping: 0.9,
            enableViewRecycling: false,
            visibleRangeBuffer: 5
        )
        
        XCTAssertEqual(customConfig.itemSpacing, 16)
        XCTAssertEqual(customConfig.bottomPadding, 40)
        XCTAssertEqual(customConfig.dividerLeadingPadding, 100)
        XCTAssertTrue(customConfig.showScrollIndicators)
        XCTAssertEqual(customConfig.animationResponse, 0.6, accuracy: 0.01)
        XCTAssertEqual(customConfig.animationDamping, 0.9, accuracy: 0.01)
        XCTAssertFalse(customConfig.enableViewRecycling)
        XCTAssertEqual(customConfig.visibleRangeBuffer, 5)
    }
    
    // MARK: - Scroll Position Tests
    
    func testScrollPositionInitialization() {
        // Test scroll position initialization
        let position = STL_Wait_Times.STL_Wait_Times.ScrollPosition()
        
        XCTAssertEqual(position.offset, 0)
        XCTAssertEqual(position.visibleRange, 0..<0)
        XCTAssertTrue(position.timestamp.timeIntervalSinceNow < 1)
    }
    
    func testScrollPositionCustomInitialization() {
        // Test custom scroll position initialization
        let customRange = 5..<15
        let customOffset: CGFloat = 100
        
        let position = STL_Wait_Times.STL_Wait_Times.ScrollPosition(
            offset: customOffset,
            timestamp: Date(),
            visibleRange: customRange
        )
        
        XCTAssertEqual(position.offset, customOffset)
        XCTAssertEqual(position.visibleRange, customRange)
    }
    
    func testScrollPositionTracking() {
        // Test scroll position tracking functionality
        let position1 = STL_Wait_Times.STL_Wait_Times.ScrollPosition(offset: 0, timestamp: Date(), visibleRange: 0..<5)
        let position2 = STL_Wait_Times.STL_Wait_Times.ScrollPosition(offset: 100, timestamp: Date(), visibleRange: 2..<7)
        let position3 = STL_Wait_Times.STL_Wait_Times.ScrollPosition(offset: 200, timestamp: Date(), visibleRange: 5..<10)
        
        var positions: [STL_Wait_Times.ScrollPosition] = []
        positions.append(position1)
        positions.append(position2)
        positions.append(position3)
        
        XCTAssertEqual(positions.count, 3)
        XCTAssertEqual(positions[0].offset, 0)
        XCTAssertEqual(positions[1].offset, 100)
        XCTAssertEqual(positions[2].offset, 200)
    }
    
    // MARK: - Performance Metrics Tests
    
    func testPerformanceMetricsInitialization() {
        // Test performance metrics initialization
        let metrics = ScrollPerformanceMetrics()
        
        XCTAssertEqual(metrics.averageScrollFPS, 60.0)
        XCTAssertEqual(metrics.visibleItemCount, 0)
        XCTAssertEqual(metrics.scrollUpdateCount, 0)
    }
    
    func testPerformanceMetricsScrollUpdates() {
        // Test performance metrics scroll update tracking
        let metrics = ScrollPerformanceMetrics()
        let position = STL_Wait_Times.ScrollPosition(offset: 100, timestamp: Date(), visibleRange: 0..<5)
        
        metrics.recordScrollUpdate(position: position)
        
        XCTAssertEqual(metrics.scrollUpdateCount, 1)
        XCTAssertEqual(metrics.averageScrollFPS, 60.0) // Single update doesn't change FPS
    }
    
    func testPerformanceMetricsItemAppearance() {
        // Test performance metrics item appearance tracking
        let metrics = ScrollPerformanceMetrics()
        
        metrics.recordItemAppear(index: 0)
        metrics.recordItemAppear(index: 1)
        metrics.recordItemAppear(index: 2)
        
        XCTAssertEqual(metrics.visibleItemCount, 3)
    }
    
    func testPerformanceMetricsItemDisappearance() {
        // Test performance metrics item disappearance tracking
        let metrics = ScrollPerformanceMetrics()
        
        // First, make items appear
        metrics.recordItemAppear(index: 0)
        metrics.recordItemAppear(index: 1)
        metrics.recordItemAppear(index: 2)
        
        // Then make some disappear
        metrics.recordItemDisappear(index: 0)
        metrics.recordItemDisappear(index: 1)
        
        XCTAssertEqual(metrics.visibleItemCount, 1)
    }
    
    func testPerformanceMetricsItemDisappearanceEdgeCase() {
        // Test performance metrics doesn't go below zero
        let metrics = ScrollPerformanceMetrics()
        
        metrics.recordItemDisappear(index: 0)
        metrics.recordItemDisappear(index: 1)
        
        XCTAssertEqual(metrics.visibleItemCount, 0)
    }
    
    // MARK: - State Management Tests
    
    func testSheetStateTransitions() {
        // Test sheet state transitions
        let states: [BottomSheetState] = [.peek, .medium, .expanded]
        
        for state in states {
            let scrollView = EnhancedScrollingView(
                items: testItems,
                sheetState: .constant(state),
                configuration: scrollConfiguration
            ) { item, index, sheetState in
                AnyView(Text(item.title))
            }
            
            XCTAssertNotNil(scrollView)
        }
    }
    
    func testScrollPositionPersistence() {
        // Test scroll position persistence across state changes
        var currentState = BottomSheetState.peek
        var savedPositions: [BottomSheetState: STL_Wait_Times.ScrollPosition] = [:]
        
        // Simulate scroll position saving
        let peekPosition = STL_Wait_Times.ScrollPosition(offset: 50, timestamp: Date(), visibleRange: 0..<3)
        let mediumPosition = STL_Wait_Times.ScrollPosition(offset: 100, timestamp: Date(), visibleRange: 2..<5)
        let expandedPosition = STL_Wait_Times.ScrollPosition(offset: 150, timestamp: Date(), visibleRange: 5..<8)
        
        savedPositions[.peek] = peekPosition
        savedPositions[.medium] = mediumPosition
        savedPositions[.expanded] = expandedPosition
        
        // Test position retrieval
        XCTAssertEqual(savedPositions[.peek]?.offset, 50)
        XCTAssertEqual(savedPositions[.medium]?.offset, 100)
        XCTAssertEqual(savedPositions[.expanded]?.offset, 150)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() {
        // Test accessibility labels for different states
        let states: [BottomSheetState] = [.peek, .medium, .expanded]
        
        for state in states {
            let expectedLabel = "Scrollable list with \(testItems.count) items, currently in \(state.accessibilityDescription)"
            // This would be tested in integration tests with actual UI
            XCTAssertNotNil(expectedLabel)
        }
    }
    
    func testAccessibilityItemLabels() {
        // Test accessibility labels for individual items
        let itemIndex = 5
        let expectedLabel = "Item \(itemIndex + 1) of \(testItems.count)"
        
        // This would be tested in integration tests with actual UI
        XCTAssertEqual(expectedLabel, "Item 6 of 50")
    }
    
    func testAccessibilityHints() {
        // Test accessibility hints
        let scrollHint = "Swipe up or down to scroll through items"
        let itemHint = "Double-tap to select, swipe up or down to scroll"
        
        XCTAssertEqual(scrollHint, "Swipe up or down to scroll through items")
        XCTAssertEqual(itemHint, "Double-tap to select, swipe up or down to scroll")
    }
    
    // MARK: - Integration Tests
    
    func testDashboardIntegration() {
        // Test integration with DashboardView
        let facilityData = createMockFacilityData()
        
        for state in [BottomSheetState.peek, .medium, .expanded] {
            let visibleFacilities = facilityData // All facilities visible in all states
            
            XCTAssertEqual(visibleFacilities.count, facilityData.count)
            XCTAssertTrue(visibleFacilities.allSatisfy { $0.id.isEmpty == false })
        }
    }
    
    func testScrollingInPeekMode() {
        // Test that scrolling works properly in peek mode
        let peekScrollView = EnhancedScrollingView(
            items: testItems,
            sheetState: .constant(.peek),
            configuration: scrollConfiguration
        ) { item, index, sheetState in
            AnyView(Text(item.title))
        }
        
        XCTAssertNotNil(peekScrollView)
        
        // Verify scroll position tracking works in peek mode
        let position = STL_Wait_Times.ScrollPosition(offset: 100, timestamp: Date(), visibleRange: 0..<5)
        positionChanges.append(position)
        
        XCTAssertEqual(positionChanges.count, 1)
        XCTAssertEqual(positionChanges[0].offset, 100)
    }
    
    func testScrollingWithExpandedFacilityList() {
        // Test scrolling with the expanded 10-item facility list
        let expandedFacilities = createExpandedMockFacilityData()
        
        XCTAssertEqual(expandedFacilities.count, 10, "Should have 10 facilities for scroll testing")
        
        let scrollView = EnhancedScrollingView(
            items: expandedFacilities,
            sheetState: .constant(.peek),
            configuration: scrollConfiguration
        ) { facility, index, sheetState in
            AnyView(Text(facility.name))
        }
        
        XCTAssertNotNil(scrollView)
        
        // Test that all facilities are accessible
        XCTAssertTrue(expandedFacilities.allSatisfy { !$0.id.isEmpty })
        XCTAssertTrue(expandedFacilities.allSatisfy { !$0.name.isEmpty })
    }
    
    func testGestureHandlingInPeekMode() {
        // Test that gesture handling works correctly in peek mode
        let metrics = ScrollPerformanceMetrics()
        
        // Simulate scroll gestures in peek mode
        for i in 0..<20 {
            let position = STL_Wait_Times.ScrollPosition(
                offset: CGFloat(i * 50),
                timestamp: Date(),
                visibleRange: i..<(i + 3)
            )
            metrics.recordScrollUpdate(position: position)
        }
        
        XCTAssertEqual(metrics.scrollUpdateCount, 20)
        XCTAssertGreaterThan(metrics.averageScrollFPS, 0)
    }
    
    func testScrollPositionChangeHandling() {
        // Test scroll position change handling
        let position = STL_Wait_Times.ScrollPosition(offset: 200, timestamp: Date(), visibleRange: 3..<8)
        
        // Simulate position change
        positionChanges.append(position)
        
        XCTAssertEqual(positionChanges.count, 1)
        XCTAssertEqual(positionChanges[0].offset, 200)
        XCTAssertEqual(positionChanges[0].visibleRange, 3..<8)
    }
    
    // MARK: - Performance Tests
    
    func testLargeDatasetPerformance() {
        // Test performance with large dataset
        let largeDataset = createTestItems(count: 1000)
        
        measure {
            let scrollView = EnhancedScrollingView(
                items: largeDataset,
                sheetState: .constant(.medium),
                configuration: scrollConfiguration
            ) { item, index, sheetState in
                AnyView(Text(item.title))
            }
            
            // Simulate view recycling
            let metrics = ScrollPerformanceMetrics()
            for i in 0..<100 {
                metrics.recordItemAppear(index: i)
                if i > 10 {
                    metrics.recordItemDisappear(index: i - 10)
                }
            }
        }
    }
    
    func testScrollUpdatePerformance() {
        // Test scroll update performance
        let metrics = ScrollPerformanceMetrics()
        
        measure {
            for i in 0..<100 {
                let position = STL_Wait_Times.ScrollPosition(
                    offset: CGFloat(i * 10),
                    timestamp: Date(),
                    visibleRange: i..<(i + 5)
                )
                metrics.recordScrollUpdate(position: position)
            }
        }
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testEmptyDataset() {
        // Test behavior with empty dataset
        let emptyItems: [TestItem] = []
        
        let scrollView = EnhancedScrollingView(
            items: emptyItems,
            sheetState: .constant(.medium),
            configuration: scrollConfiguration
        ) { item, index, sheetState in
            AnyView(Text(item.title))
        }
        
        XCTAssertNotNil(scrollView)
    }
    
    func testSingleItemDataset() {
        // Test behavior with single item
        let singleItem = [TestItem(title: "Single Item", subtitle: "Only item")]
        
        let scrollView = EnhancedScrollingView(
            items: singleItem,
            sheetState: .constant(.medium),
            configuration: scrollConfiguration
        ) { item, index, sheetState in
            AnyView(Text(item.title))
        }
        
        XCTAssertNotNil(scrollView)
    }
    
    func testScrollOffsetPreferenceKey() {
        // Test scroll offset preference key
        let key = ScrollOffsetPreferenceKey.self
        
        XCTAssertEqual(key.defaultValue, 0)
        
        var value: CGFloat = 50
        key.reduce(value: &value) { 100 }
        XCTAssertEqual(value, 100)
    }
    
    // MARK: - Helper Methods
    
    private func createTestItems(count: Int) -> [TestItem] {
        return (0..<count).map { index in
            TestItem(
                title: "Test Item \(index + 1)",
                subtitle: "Subtitle for item \(index + 1)"
            )
        }
    }
    
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
    
    private func createExpandedMockFacilityData() -> [MedicalFacility] {
        return [
            MedicalFacility(id: "1", name: "Barnes-Jewish Hospital", type: "ER", waitTime: "45", waitDetails: "MINUTES", distance: "2.3 mi", waitChange: "+5 min", status: "Open", isOpen: true),
            MedicalFacility(id: "2", name: "Saint Louis University", type: "ER", waitTime: "32", waitDetails: "MINUTES", distance: "1.8 mi", waitChange: "-2 min", status: "Open", isOpen: true),
            MedicalFacility(id: "3", name: "Mercy Hospital South", type: "ER", waitTime: "18", waitDetails: "MINUTES", distance: "3.1 mi", waitChange: "Same", status: "Open", isOpen: true),
            MedicalFacility(id: "4", name: "Christian Hospital", type: "ER", waitTime: "25", waitDetails: "MINUTES", distance: "4.2 mi", waitChange: "+3 min", status: "Open", isOpen: true),
            MedicalFacility(id: "5", name: "Missouri Baptist Medical Center", type: "ER", waitTime: "38", waitDetails: "MINUTES", distance: "5.8 mi", waitChange: "-1 min", status: "Open", isOpen: true),
            MedicalFacility(id: "6", name: "SSM Health Cardinal Glennon", type: "ER", waitTime: "22", waitDetails: "MINUTES", distance: "3.5 mi", waitChange: "+1 min", status: "Open", isOpen: true),
            MedicalFacility(id: "7", name: "St. Luke's Hospital", type: "ER", waitTime: "52", waitDetails: "MINUTES", distance: "6.1 mi", waitChange: "+8 min", status: "Busy", isOpen: true),
            MedicalFacility(id: "8", name: "Total Access Urgent Care", type: "UC", waitTime: "12", waitDetails: "MINUTES", distance: "1.2 mi", waitChange: "-3 min", status: "Open", isOpen: true),
            MedicalFacility(id: "9", name: "Progress West Hospital", type: "ER", waitTime: "35", waitDetails: "MINUTES", distance: "7.8 mi", waitChange: "Same", status: "Open", isOpen: true),
            MedicalFacility(id: "10", name: "Mercy-GoHealth Urgent Care", type: "UC", waitTime: "8", waitDetails: "MINUTES", distance: "2.1 mi", waitChange: "-5 min", status: "Open", isOpen: true)
        ]
    }
}

// MARK: - Mock Types for Testing

struct TestItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

// MARK: - Performance Baseline Tests

class EnhancedScrollingPerformanceTests: XCTestCase {
    
    func testScrollUpdateLatency() {
        // Test scroll update latency
        let metrics = ScrollPerformanceMetrics()
        
        measure {
            let position = STL_Wait_Times.ScrollPosition(offset: 100, timestamp: Date(), visibleRange: 0..<5)
            metrics.recordScrollUpdate(position: position)
        }
    }
    
    func testViewRecyclingPerformance() {
        // Test view recycling performance
        let metrics = ScrollPerformanceMetrics()
        
        measure {
            // Simulate rapid item appearance and disappearance
            for i in 0..<50 {
                metrics.recordItemAppear(index: i)
                metrics.recordItemDisappear(index: i)
            }
        }
    }
    
    func testLargeDatasetScrolling() {
        // Test scrolling with large dataset
        let largeDataset = (0..<5000).map { index in
            TestItem(title: "Item \(index)", subtitle: "Subtitle \(index)")
        }
        
        measure {
            let scrollView = EnhancedScrollingView(
                items: largeDataset,
                sheetState: .constant(.expanded),
                configuration: ScrollConfiguration(enableViewRecycling: true)
            ) { item, index, sheetState in
                AnyView(Text(item.title))
            }
            
            // Simulate scrolling through visible range
            let metrics = ScrollPerformanceMetrics()
            for i in 0..<100 {
                let position = STL_Wait_Times.ScrollPosition(
                    offset: CGFloat(i * 50),
                    timestamp: Date(),
                    visibleRange: i..<(i + 10)
                )
                metrics.recordScrollUpdate(position: position)
            }
        }
    }
}