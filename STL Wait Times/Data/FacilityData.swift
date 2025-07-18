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
        ),
        
        // Bridgeton Total Access location (Hospital ID 12604)
        Facility(
            id: "total-access-12604",
            name: "Total Access Urgent Care - Bridgeton",
            address: "12409 St. Charles Rock Rd",
            city: "Bridgeton",
            state: "MO",
            zipCode: "63044",
            phone: "(314) 455-4046",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7606, longitude: -90.4190),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12604/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12604/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Chesterfield Total Access location (Hospital ID 13242)
        Facility(
            id: "total-access-13242",
            name: "Total Access Urgent Care - Chesterfield",
            address: "13426 Olive Blvd",
            city: "Chesterfield",
            state: "MO",
            zipCode: "63017",
            phone: "(636) 200-9500",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6630, longitude: -90.5770),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/13242/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/13242/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Collinsville Total Access location (Hospital ID 15883)
        Facility(
            id: "total-access-15883",
            name: "Total Access Urgent Care - Collinsville",
            address: "400 Beltline Rd",
            city: "Collinsville",
            state: "IL",
            zipCode: "62234",
            phone: "(618) 000-0000",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6703, longitude: -89.9854),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/15883/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/15883/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Creve Coeur Total Access location (Hospital ID 12603)
        Facility(
            id: "total-access-12603",
            name: "Total Access Urgent Care - Creve Coeur",
            address: "10923 Olive Blvd",
            city: "Creve Coeur",
            state: "MO",
            zipCode: "63141",
            phone: "(314) 764-2953",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6530, longitude: -90.4240),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12603/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12603/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Ellisville Total Access location (Hospital ID 12607)
        Facility(
            id: "total-access-12607",
            name: "Total Access Urgent Care - Ellisville",
            address: "15420 Manchester Rd",
            city: "Ellisville",
            state: "MO",
            zipCode: "63011",
            phone: "(636) 220-9727",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5940, longitude: -90.5860),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12607/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12607/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Festus Total Access location (Hospital ID 12617)
        Facility(
            id: "total-access-12617",
            name: "Total Access Urgent Care - Festus",
            address: "408 Brothers Ave",
            city: "Festus",
            state: "MO",
            zipCode: "63028",
            phone: "(636) 429-0999",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.2203, longitude: -90.3935),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12617/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12617/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // First Capitol Total Access location (Hospital ID 12611)
        Facility(
            id: "total-access-12611",
            name: "Total Access Urgent Care - First Capitol",
            address: "2138 1st Capitol Dr",
            city: "St. Charles",
            state: "MO",
            zipCode: "63301",
            phone: "(636) 000-0000",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7917, longitude: -90.4890),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12611/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12611/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Florissant Total Access location (Hospital ID 12602)
        Facility(
            id: "total-access-12602",
            name: "Total Access Urgent Care - Florissant",
            address: "1090 N Hwy 67",
            city: "Florissant",
            state: "MO",
            zipCode: "63031",
            phone: "(314) 778-3186",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7892, longitude: -90.3223),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12602/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12602/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Hampton Total Access location (Hospital ID 12610)
        Facility(
            id: "total-access-12610",
            name: "Total Access Urgent Care - Hampton",
            address: "2060 Hampton Ave",
            city: "St. Louis",
            state: "MO",
            zipCode: "63139",
            phone: "(314) 696-2341",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6103, longitude: -90.2954),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12610/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12610/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Holly Hills Total Access location (Hospital ID 13110)
        Facility(
            id: "total-access-13110",
            name: "Total Access Urgent Care - Holly Hills",
            address: "4318 Loughborough Ave",
            city: "St. Louis",
            state: "MO",
            zipCode: "63116",
            phone: "(314) 641-6002",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5958, longitude: -90.2865),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/13110/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/13110/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Lake St. Louis Total Access location (Hospital ID 12600)
        Facility(
            id: "total-access-12600",
            name: "Total Access Urgent Care - Lake St. Louis",
            address: "1001 Southern Ridge Ln",
            city: "Lake St. Louis",
            state: "MO",
            zipCode: "63367",
            phone: "(636) 265-6230",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7789, longitude: -90.7846),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12600/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12600/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // O'Fallon North Total Access location (Hospital ID 12620)
        Facility(
            id: "total-access-12620",
            name: "Total Access Urgent Care - O'Fallon North",
            address: "507 S Main St",
            city: "O'Fallon",
            state: "MO",
            zipCode: "63366",
            phone: "(636) 409-1132",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.8106, longitude: -90.7126),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12620/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12620/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // O'Fallon South Total Access location (Hospital ID 12618)
        Facility(
            id: "total-access-12618",
            name: "Total Access Urgent Care - O'Fallon South",
            address: "4201 State Hwy K",
            city: "O'Fallon",
            state: "MO",
            zipCode: "63368",
            phone: "(636) 294-8540",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.8066, longitude: -90.6954),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12618/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12618/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // O'Fallon Illinois Total Access location (Hospital ID 15884)
        Facility(
            id: "total-access-15884",
            name: "Total Access Urgent Care - O'Fallon, IL",
            address: "1103 Central Park Dr",
            city: "O'Fallon",
            state: "IL",
            zipCode: "62269",
            phone: "(618) 632-3000",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5906, longitude: -89.9107),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/15884/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/15884/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Oakville Total Access location (Hospital ID 12619)
        Facility(
            id: "total-access-12619",
            name: "Total Access Urgent Care - Oakville",
            address: "4400 Telegraph Rd",
            city: "St. Louis",
            state: "MO",
            zipCode: "63129",
            phone: "(314) 343-0056",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5494, longitude: -90.3029),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12619/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12619/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Overland Total Access location (Hospital ID 12623)
        Facility(
            id: "total-access-12623",
            name: "Total Access Urgent Care - Overland",
            address: "8961 Page Ave",
            city: "Overland",
            state: "MO",
            zipCode: "63114",
            phone: "(314) 476-6175",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7017, longitude: -90.3651),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12623/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12623/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Richmond Heights Total Access location (Hospital ID 12601)
        Facility(
            id: "total-access-12601",
            name: "Total Access Urgent Care - Richmond Heights",
            address: "1005 S Big Bend Blvd",
            city: "Richmond Heights",
            state: "MO",
            zipCode: "63117",
            phone: "(314) 449-8677",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.3220),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12601/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12601/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Rock Hill Total Access location (Hospital ID 12626)
        Facility(
            id: "total-access-12626",
            name: "Total Access Urgent Care - Rock Hill",
            address: "9556 Manchester Rd",
            city: "St. Louis",
            state: "MO",
            zipCode: "63119",
            phone: "(314) 373-5740",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6134, longitude: -90.3598),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12626/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12626/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // South County Total Access location (Hospital ID 12605)
        Facility(
            id: "total-access-12605",
            name: "Total Access Urgent Care - South County",
            address: "12616 Lamplighter Square Shopping Center",
            city: "St. Louis",
            state: "MO",
            zipCode: "63128",
            phone: "(314) 669-9193",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5351, longitude: -90.4046),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12605/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12605/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // St. Charles (Cave Springs) Total Access location (Hospital ID 12616)
        Facility(
            id: "total-access-12616",
            name: "Total Access Urgent Care - St. Charles",
            address: "3909 Mexico Rd",
            city: "St. Charles",
            state: "MO",
            zipCode: "63376",
            phone: "(636) 477-6344",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7881, longitude: -90.4974),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12616/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12616/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // St. Louis Hills Total Access location (Hospital ID 12622)
        Facility(
            id: "total-access-12622",
            name: "Total Access Urgent Care - St. Louis Hills",
            address: "6900 Chippewa St",
            city: "St. Louis",
            state: "MO",
            zipCode: "63109",
            phone: "(314) 899-9344",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5764, longitude: -90.3370),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12622/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12622/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // St. Peters Total Access location (Hospital ID 12621)
        Facility(
            id: "total-access-12621",
            name: "Total Access Urgent Care - St. Peters",
            address: "600 Mid Rivers Mall Dr",
            city: "St. Peters",
            state: "MO",
            zipCode: "63376",
            phone: "(636) 224-3208",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7869, longitude: -90.6298),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12621/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12621/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Tower Grove Total Access location (Hospital ID 12614)
        Facility(
            id: "total-access-12614",
            name: "Total Access Urgent Care - Tower Grove",
            address: "3114 S Grand Blvd",
            city: "St. Louis",
            state: "MO",
            zipCode: "63118",
            phone: "(314) 696-2178",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5959, longitude: -90.2307),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12614/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12614/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Town & Country Total Access location (Hospital ID 12606)
        Facility(
            id: "total-access-12606",
            name: "Total Access Urgent Care - Town & Country",
            address: "13861 Manchester Rd",
            city: "Ballwin",
            state: "MO",
            zipCode: "63011",
            phone: "(636) 220-9333",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5958, longitude: -90.5926),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12606/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12606/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Valley Park Total Access location (Hospital ID 12613)
        Facility(
            id: "total-access-12613",
            name: "Total Access Urgent Care - Valley Park",
            address: "2980 Dougherty Ferry Rd",
            city: "Kirkwood",
            state: "MO",
            zipCode: "63122",
            phone: "(636) 529-8411",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5453, longitude: -90.4052),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12613/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12613/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Washington Total Access location (Hospital ID 12608)
        Facility(
            id: "total-access-12608",
            name: "Total Access Urgent Care - Washington",
            address: "1717 Madison Ave",
            city: "Washington",
            state: "MO",
            zipCode: "63090",
            phone: "(636) 244-6950",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5581, longitude: -91.0126),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12608/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12608/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Wentzville Total Access location (Hospital ID 12609)
        Facility(
            id: "total-access-12609",
            name: "Total Access Urgent Care - Wentzville",
            address: "1890 Wentzville Pkwy",
            city: "Wentzville",
            state: "MO",
            zipCode: "63385",
            phone: "(636) 887-2667",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.8106, longitude: -90.8529),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12609/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12609/visits/new",
            operatingHours: .standardUrgentCare
        )
        // Testing all thirty-one Total Access facilities with improved batch processing
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