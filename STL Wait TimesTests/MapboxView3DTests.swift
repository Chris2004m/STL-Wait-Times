//
//  MapboxView3DTests.swift
//  STL Wait TimesTests
//
//  Comprehensive tests for 3D Mapbox integration
//  Created by Claude AI on 7/15/25.
//

import XCTest
import SwiftUI
import CoreLocation
@testable import STL_Wait_Times

/// **MapboxView3DTests**: Comprehensive test suite for 3D Mapbox functionality
///
/// This test suite covers:
/// - 3D map mode transitions and state management
/// - Annotation conversion and display logic
/// - Performance optimization and device capability detection
/// - Accessibility features and compliance
/// - User interaction handling and haptic feedback
/// - Data conversion accuracy and edge cases
final class MapboxView3DTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var mapView: MapboxView3D!
    var sampleRegion: MKCoordinateRegion!
    var sampleAnnotations: [MedicalFacility3DAnnotation]!
    var dataConverter: MapboxDataConverter!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize test components
        sampleRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        sampleAnnotations = createSampleAnnotations()
        dataConverter = MapboxDataConverter()
        
        // Create map view for testing
        mapView = MapboxView3D(
            coordinateRegion: .constant(sampleRegion),
            annotations: sampleAnnotations,
            mapMode: .hybrid2D
        )
    }
    
    override func tearDownWithError() throws {
        mapView = nil
        sampleRegion = nil
        sampleAnnotations = nil
        dataConverter = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Map Display Mode Tests
    
    /// Test all map display modes are properly defined and accessible
    func testMapDisplayModes() throws {
        // Test all cases exist
        let allModes = MapDisplayMode.allCases
        XCTAssertEqual(allModes.count, 5, "Should have exactly 5 map display modes")
        
        // Test specific modes
        XCTAssertTrue(allModes.contains(.flat2D))
        XCTAssertTrue(allModes.contains(.hybrid2D))
        XCTAssertTrue(allModes.contains(.buildings3D))
        XCTAssertTrue(allModes.contains(.terrain3D))
        XCTAssertTrue(allModes.contains(.full3D))
    }
    
    /// Test 3D support detection for each map mode
    func testMapMode3DSupport() throws {
        // 2D modes should not support 3D
        XCTAssertFalse(MapDisplayMode.flat2D.supports3D)
        XCTAssertFalse(MapDisplayMode.hybrid2D.supports3D)
        
        // 3D modes should support 3D
        XCTAssertTrue(MapDisplayMode.buildings3D.supports3D)
        XCTAssertTrue(MapDisplayMode.terrain3D.supports3D)
        XCTAssertTrue(MapDisplayMode.full3D.supports3D)
    }
    
    /// Test accessibility labels for map modes
    func testMapModeAccessibilityLabels() throws {
        XCTAssertFalse(MapDisplayMode.flat2D.accessibilityLabel.isEmpty)
        XCTAssertFalse(MapDisplayMode.buildings3D.accessibilityLabel.isEmpty)
        XCTAssertFalse(MapDisplayMode.full3D.accessibilityLabel.isEmpty)
        
        // Test specific content
        XCTAssertTrue(MapDisplayMode.flat2D.accessibilityLabel.contains("Two-dimensional"))
        XCTAssertTrue(MapDisplayMode.buildings3D.accessibilityLabel.contains("Three-dimensional"))
        XCTAssertTrue(MapDisplayMode.terrain3D.accessibilityLabel.contains("terrain"))
    }
    
    /// Test map mode icon assignments
    func testMapModeIcons() throws {
        // All modes should have valid SF Symbol names
        for mode in MapDisplayMode.allCases {
            XCTAssertFalse(mode.iconName.isEmpty, "Mode \(mode) should have an icon")
        }
        
        // Test specific icons exist
        XCTAssertEqual(MapDisplayMode.flat2D.iconName, "map")
        XCTAssertEqual(MapDisplayMode.buildings3D.iconName, "building.2.crop.circle")
        XCTAssertEqual(MapDisplayMode.full3D.iconName, "globe.americas.fill")
    }
    
    // MARK: - Annotation Tests
    
    /// Test 3D annotation creation and properties
    func testMedicalFacility3DAnnotation() throws {
        let annotation = sampleAnnotations.first!
        
        // Test required properties
        XCTAssertFalse(annotation.id.isEmpty)
        XCTAssertFalse(annotation.name.isEmpty)
        XCTAssertTrue(annotation.buildingHeight > 0)
        
        // Test coordinate validity
        XCTAssertTrue(CLLocationCoordinate2DIsValid(annotation.coordinate))
        
        // Test priority level
        XCTAssertTrue(annotation.priorityLevel.scale >= 0.8)
        XCTAssertTrue(annotation.priorityLevel.scale <= 1.2)
    }
    
    /// Test facility type properties and colors
    func testFacilityTypes() throws {
        let emergencyAnnotation = MedicalFacility3DAnnotation(
            id: "test-ed",
            coordinate: sampleRegion.center,
            name: "Test Emergency",
            facilityType: .emergencyDepartment,
            waitTime: 30,
            waitTimeChange: nil,
            distance: nil,
            isOpen: true,
            buildingHeight: 80.0,
            priorityLevel: .high,
            customIcon: nil
        )
        
        // Test emergency department
        XCTAssertEqual(emergencyAnnotation.facilityType.color, .red)
        XCTAssertEqual(emergencyAnnotation.facilityType.icon, "cross.circle.fill")
        
        // Test urgent care
        let urgentCareAnnotation = MedicalFacility3DAnnotation(
            id: "test-uc",
            coordinate: sampleRegion.center,
            name: "Test Urgent Care",
            facilityType: .urgentCare,
            waitTime: 15,
            waitTimeChange: nil,
            distance: nil,
            isOpen: true,
            buildingHeight: 25.0,
            priorityLevel: .medium,
            customIcon: nil
        )
        
        XCTAssertEqual(urgentCareAnnotation.facilityType.color, .orange)
        XCTAssertEqual(urgentCareAnnotation.facilityType.icon, "stethoscope.circle.fill")
    }
    
    /// Test priority level calculations and scaling
    func testPriorityLevels() throws {
        // Test all priority levels
        for level in [MedicalFacility3DAnnotation.PriorityLevel.low,
                     .medium, .high, .critical] {
            XCTAssertTrue(level.scale >= 0.8)
            XCTAssertTrue(level.scale <= 1.2)
        }
        
        // Test ascending scale
        XCTAssertLessThan(MedicalFacility3DAnnotation.PriorityLevel.low.scale,
                         MedicalFacility3DAnnotation.PriorityLevel.medium.scale)
        XCTAssertLessThan(MedicalFacility3DAnnotation.PriorityLevel.medium.scale,
                         MedicalFacility3DAnnotation.PriorityLevel.high.scale)
        XCTAssertLessThan(MedicalFacility3DAnnotation.PriorityLevel.high.scale,
                         MedicalFacility3DAnnotation.PriorityLevel.critical.scale)
    }
    
    // MARK: - Data Conversion Tests
    
    /// Test medical facility to 3D annotation conversion
    func testDataConversion() throws {
        let sampleFacilities = createSampleMedicalFacilities()
        let sampleWaitTimes = createSampleWaitTimes()
        
        let convertedAnnotations = dataConverter.convertToMapbox3DAnnotations(
            facilities: sampleFacilities,
            waitTimes: sampleWaitTimes,
            userLocation: nil
        )
        
        // Test conversion count
        XCTAssertEqual(convertedAnnotations.count, sampleFacilities.count)
        
        // Test data integrity
        for (index, annotation) in convertedAnnotations.enumerated() {
            let originalFacility = sampleFacilities[index]
            
            XCTAssertEqual(annotation.id, originalFacility.id)
            XCTAssertEqual(annotation.name, originalFacility.name)
            XCTAssertEqual(annotation.coordinate.latitude, originalFacility.coordinate.latitude, accuracy: 0.0001)
            XCTAssertEqual(annotation.coordinate.longitude, originalFacility.coordinate.longitude, accuracy: 0.0001)
        }
    }
    
    /// Test priority calculation logic
    func testPriorityCalculation() throws {
        let lowWaitFacility = createTestFacility(waitTime: 10) // Should be high priority
        let highWaitFacility = createTestFacility(waitTime: 90) // Should be low priority
        
        let lowWaitAnnotations = dataConverter.convertToMapbox3DAnnotations(
            facilities: [lowWaitFacility],
            waitTimes: ["low": WaitTime(waitMinutes: 10, source: "test", lastUpdated: Date())]
        )
        
        let highWaitAnnotations = dataConverter.convertToMapbox3DAnnotations(
            facilities: [highWaitFacility],
            waitTimes: ["high": WaitTime(waitMinutes: 90, source: "test", lastUpdated: Date())]
        )
        
        XCTAssertGreaterThan(lowWaitAnnotations.first!.priorityLevel.rawValue,
                           highWaitAnnotations.first!.priorityLevel.rawValue)
    }
    
    /// Test distance-based priority adjustment
    func testDistanceBasedPriority() throws {
        let userLocation = CLLocation(latitude: 38.6270, longitude: -90.1994)
        
        let nearFacility = MedicalFacility(
            id: "near",
            name: "Near Facility",
            coordinate: CLLocationCoordinate2D(latitude: 38.6280, longitude: -90.1984), // ~100m away
            type: "ED",
            isOpen: true
        )
        
        let farFacility = MedicalFacility(
            id: "far", 
            name: "Far Facility",
            coordinate: CLLocationCoordinate2D(latitude: 38.7270, longitude: -90.2994), // ~15km away
            type: "ED",
            isOpen: true
        )
        
        let nearAnnotations = dataConverter.convertToMapbox3DAnnotations(
            facilities: [nearFacility],
            userLocation: userLocation
        )
        
        let farAnnotations = dataConverter.convertToMapbox3DAnnotations(
            facilities: [farFacility],
            userLocation: userLocation
        )
        
        // Near facility should have higher priority
        XCTAssertGreaterThanOrEqual(nearAnnotations.first!.priorityLevel.rawValue,
                                   farAnnotations.first!.priorityLevel.rawValue)
    }
    
    // MARK: - Performance Tests
    
    /// Test performance manager initialization and capabilities
    func testPerformanceManager() throws {
        let performanceManager = Map3DPerformanceManager()
        
        // Test initial state
        XCTAssertTrue(performanceManager.supports3D) // Should default to true
        XCTAssertEqual(performanceManager.recommendedQuality, .auto)
        
        // Test capability detection
        performanceManager.detectDeviceCapabilities()
        
        // Should still be configured
        XCTAssertNotNil(performanceManager.recommendedQuality)
    }
    
    /// Test render quality frame rate targets
    func testRenderQualityTargets() throws {
        XCTAssertEqual(RenderQuality.low.targetFrameRate, 30.0)
        XCTAssertEqual(RenderQuality.medium.targetFrameRate, 45.0)
        XCTAssertEqual(RenderQuality.high.targetFrameRate, 60.0)
        XCTAssertEqual(RenderQuality.auto.targetFrameRate, 60.0)
    }
    
    /// Test annotation conversion performance with large datasets
    func testLargeDatasetPerformance() throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create large dataset
        let largeFacilitySet = (0..<1000).map { index in
            MedicalFacility(
                id: "facility-\(index)",
                name: "Test Facility \(index)",
                coordinate: CLLocationCoordinate2D(
                    latitude: 38.6270 + Double(index) * 0.001,
                    longitude: -90.1994 + Double(index) * 0.001
                ),
                type: "ED",
                isOpen: true
            )
        }
        
        let convertedAnnotations = dataConverter.convertToMapbox3DAnnotations(
            facilities: largeFacilitySet
        )
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Should convert 1000 facilities in under 1 second
        XCTAssertLessThan(executionTime, 1.0, "Large dataset conversion should be fast")
        XCTAssertEqual(convertedAnnotations.count, 1000)
    }
    
    // MARK: - Edge Case Tests
    
    /// Test handling of invalid coordinates
    func testInvalidCoordinates() throws {
        let invalidFacility = MedicalFacility(
            id: "invalid",
            name: "Invalid Facility",
            coordinate: CLLocationCoordinate2D(latitude: 999.0, longitude: 999.0), // Invalid
            type: "ED",
            isOpen: true
        )
        
        let annotations = dataConverter.convertToMapbox3DAnnotations(
            facilities: [invalidFacility]
        )
        
        // Should still create annotation, but with clamped coordinates
        XCTAssertEqual(annotations.count, 1)
        XCTAssertFalse(CLLocationCoordinate2DIsValid(annotations.first!.coordinate)) // Will be invalid
    }
    
    /// Test handling of missing wait time data
    func testMissingWaitTimeData() throws {
        let facility = createTestFacility(waitTime: nil)
        
        let annotations = dataConverter.convertToMapbox3DAnnotations(
            facilities: [facility],
            waitTimes: [:] // Empty wait times
        )
        
        XCTAssertEqual(annotations.count, 1)
        XCTAssertNil(annotations.first!.waitTime)
        XCTAssertNil(annotations.first!.waitTimeChange)
    }
    
    /// Test handling of closed facilities
    func testClosedFacilities() throws {
        let closedFacility = MedicalFacility(
            id: "closed",
            name: "Closed Facility",
            coordinate: sampleRegion.center,
            type: "ED",
            isOpen: false
        )
        
        // Test including closed facilities
        let annotationsWithClosed = dataConverter.convertToMapbox3DAnnotations(
            facilities: [closedFacility],
            includeClosedFacilities: true
        )
        XCTAssertEqual(annotationsWithClosed.count, 1)
        XCTAssertFalse(annotationsWithClosed.first!.isOpen)
        
        // Test excluding closed facilities
        let annotationsWithoutClosed = dataConverter.convertToMapbox3DAnnotations(
            facilities: [closedFacility],
            includeClosedFacilities: false
        )
        XCTAssertEqual(annotationsWithoutClosed.count, 0)
    }
    
    // MARK: - Accessibility Tests
    
    /// Test accessibility labels for annotation views
    func testAnnotationAccessibilityLabels() throws {
        let annotation = sampleAnnotations.first!
        let annotationView = MedicalFacility3DAnnotationView(
            annotation: annotation,
            displayMode: .buildings3D,
            onTap: {}
        )
        
        // Test that accessibility label is properly formed
        // This would require ViewInspector or similar framework for SwiftUI testing
        // For now, we test the data that feeds into the label
        XCTAssertFalse(annotation.name.isEmpty)
        XCTAssertTrue(annotation.isOpen)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleAnnotations() -> [MedicalFacility3DAnnotation] {
        return [
            MedicalFacility3DAnnotation(
                id: "test1",
                coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
                name: "Test Hospital",
                facilityType: .emergencyDepartment,
                waitTime: 45,
                waitTimeChange: "+5 min",
                distance: "2.3 mi",
                isOpen: true,
                buildingHeight: 100.0,
                priorityLevel: .high,
                customIcon: nil
            ),
            MedicalFacility3DAnnotation(
                id: "test2",
                coordinate: CLLocationCoordinate2D(latitude: 38.6370, longitude: -90.2094),
                name: "Test Urgent Care",
                facilityType: .urgentCare,
                waitTime: 15,
                waitTimeChange: "-2 min",
                distance: "1.8 mi",
                isOpen: true,
                buildingHeight: 25.0,
                priorityLevel: .medium,
                customIcon: nil
            )
        ]
    }
    
    private func createSampleMedicalFacilities() -> [MedicalFacility] {
        return [
            MedicalFacility(
                id: "facility1",
                name: "Sample Hospital",
                coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
                type: "ED",
                isOpen: true
            ),
            MedicalFacility(
                id: "facility2",
                name: "Sample Urgent Care",
                coordinate: CLLocationCoordinate2D(latitude: 38.6370, longitude: -90.2094),
                type: "UC",
                isOpen: true
            )
        ]
    }
    
    private func createSampleWaitTimes() -> [String: WaitTime] {
        return [
            "facility1": WaitTime(waitMinutes: 45, source: "test", lastUpdated: Date()),
            "facility2": WaitTime(waitMinutes: 15, source: "test", lastUpdated: Date())
        ]
    }
    
    private func createTestFacility(waitTime: Int?) -> MedicalFacility {
        return MedicalFacility(
            id: waitTime != nil ? "facility-\(waitTime!)" : "facility-no-wait",
            name: "Test Facility",
            coordinate: sampleRegion.center,
            type: "ED",
            isOpen: true
        )
    }
}

// MARK: - Performance Test Extensions

extension MapboxView3DTests {
    
    /// Measure annotation view rendering performance
    func testAnnotationViewRenderingPerformance() throws {
        let annotation = sampleAnnotations.first!
        
        measure {
            for _ in 0..<100 {
                let annotationView = MedicalFacility3DAnnotationView(
                    annotation: annotation,
                    displayMode: .buildings3D,
                    onTap: {}
                )
                // In a real test, we'd render this view
                _ = annotationView.body
            }
        }
    }
    
    /// Measure map mode switching performance
    func testMapModeSwitchingPerformance() throws {
        measure {
            for mode in MapDisplayMode.allCases {
                // Simulate mode switching overhead
                _ = mode.supports3D
                _ = mode.accessibilityLabel
                _ = mode.iconName
            }
        }
    }
}