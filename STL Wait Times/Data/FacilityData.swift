import Foundation
import CoreLocation

/// Static facility data for St. Louis metro area
struct FacilityData {
    
    /// TESTING: Total Access locations with web scraping for patients in line feature
    static let allFacilities: [Facility] = [
        // University City Total Access location
        Facility(
            id: "total-access-13598",
            name: "Total Access Urgent Care - University City",
            address: "8213 Delmar Blvd",
            city: "University City",
            state: "MO",
            zipCode: "63124",
            phone: "(314) 219-8985",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6560, longitude: -90.3090),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/13598/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/13598/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Affton Total Access location
        Facility(
            id: "total-access-12625",
            name: "Total Access Urgent Care - Affton",
            address: "9538 Gravois Rd",
            city: "Affton",
            state: "MO",
            zipCode: "63123",
            phone: "(314) 932-0817",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5507, longitude: -90.3254),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12625/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12625/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Kirkwood North Total Access location
        Facility(
            id: "total-access-12624",
            name: "Total Access Urgent Care - Kirkwood North",
            address: "915 North Kirkwood Rd",
            city: "Kirkwood",
            state: "MO",
            zipCode: "63122",
            phone: "(314) 932-0810",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5945, longitude: -90.4068),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12624/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12624/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Ballwin Total Access location
        Facility(
            id: "total-access-12612",
            name: "Total Access Urgent Care - Ballwin",
            address: "Ballwin Location",
            city: "Ballwin",
            state: "MO",
            zipCode: "63011",
            phone: "(314) 000-0000",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5954, longitude: -90.5464),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12612/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12612/visits/new",
            operatingHours: .standardUrgentCare
        )
        // Testing all four Total Access facilities with patients in line feature
    ]
    
    /// Emergency departments only
    static var emergencyDepartments: [Facility] {
        return allFacilities.filter { $0.facilityType == .emergencyDepartment }
    }
    
    /// Urgent care centers only
    static var urgentCareCenters: [Facility] {
        return allFacilities.filter { $0.facilityType == .urgentCare }
    }
    
    /// Facilities with API endpoints (for wait time fetching)
    static var facilitiesWithAPIs: [Facility] {
        return allFacilities.filter { $0.apiEndpoint != nil }
    }
    
    /// Get facility by ID
    static func facility(withId id: String) -> Facility? {
        allFacilities.first { $0.id == id }
    }
    
    /// Get facilities within a radius of a location
    static func facilities(within radius: CLLocationDistance, of location: CLLocation) -> [Facility] {
        return allFacilities.filter { facility in
            let facilityLocation = CLLocation(
                latitude: facility.coordinate.latitude,
                longitude: facility.coordinate.longitude
            )
            return location.distance(from: facilityLocation) <= radius
        }
    }
}