import XCTest
import CoreLocation
@testable import STL_Wait_Times

final class MapboxView3DTests: XCTestCase {
    private let converter = MapboxDataConverter()

    func testConvertToMapboxAnnotationsReturnsMatchingCount() {
        let facilities = Array(FacilityData.allFacilities.prefix(3))
        let annotations = converter.convertToMapboxAnnotations(facilities: facilities)
        XCTAssertEqual(annotations.count, facilities.count)
        XCTAssertEqual(Set(annotations.map { $0.id }), Set(facilities.map { $0.id }))
    }

    func testConvertToMapboxAnnotationsCanExcludeClosedFacilities() {
        let closedHours = OperatingHours(
            monday: .closed,
            tuesday: .closed,
            wednesday: .closed,
            thursday: .closed,
            friday: .closed,
            saturday: .closed,
            sunday: .closed
        )

        let closedFacility = Facility(
            id: "closed-facility",
            name: "Closed Facility",
            address: "1 Test Way",
            city: "St. Louis",
            state: "MO",
            zipCode: "63101",
            phone: "314-555-1212",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.627, longitude: -90.1994),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil,
            websiteURL: nil,
            operatingHours: closedHours
        )

        let annotations = converter.convertToMapboxAnnotations(
            facilities: [closedFacility],
            includeClosedFacilities: false
        )
        XCTAssertTrue(annotations.isEmpty)
    }

    func testWaitTimeMappingUsesProvidedValues() {
        guard let facility = FacilityData.allFacilities.first else {
            XCTFail("Fixture data unavailable")
            return
        }

        let waitTime = WaitTime(
            facilityId: facility.id,
            waitMinutes: 42,
            patientsInLine: 5,
            lastUpdated: Date(),
            nextAvailableSlot: 10,
            status: .open,
            waitTimeRange: nil
        )

        let annotations = converter.convertToMapboxAnnotations(
            facilities: [facility],
            waitTimes: [facility.id: waitTime]
        )

        XCTAssertEqual(annotations.count, 1)
        XCTAssertTrue(annotations[0].subtitle?.contains("42") ?? false)
    }
}
