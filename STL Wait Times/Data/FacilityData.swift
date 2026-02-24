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
            city: "Saint Louis",
            state: "MO",
            zipCode: "63124",
            phone: "(314) 219-8985",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6607797, longitude: -90.3496339),
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
            coordinate: CLLocationCoordinate2D(latitude: 38.5524875, longitude: -90.3230356),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12625/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12625/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Kirkwood North Total Access location
        Facility(
            id: "total-access-12624",
            name: "Total Access Urgent Care - Kirkwood North",
            address: "915 N Kirkwood Rd",
            city: "Kirkwood",
            state: "MO",
            zipCode: "63122",
            phone: "(314) 932-0810",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5974541, longitude: -90.4067422),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12624/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12624/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Ballwin Total Access location
        Facility(
            id: "total-access-12612",
            name: "Total Access Urgent Care - Ballwin",
            address: "2501 Clarkson Rd",
            city: "Chesterfield",
            state: "MO",
            zipCode: "63017",
            phone: "(636) 778-9989",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6212307, longitude: -90.582767),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12612/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12612/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Bridgeton Total Access location (Hospital ID 12604)
        Facility(
            id: "total-access-12604",
            name: "Total Access Urgent Care - Bridgeton",
            address: "12409 Saint Charles Rock Rd",
            city: "Bridgeton",
            state: "MO",
            zipCode: "63044",
            phone: "(314) 455-4046",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7551327, longitude: -90.4299364),
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
            coordinate: CLLocationCoordinate2D(latitude: 38.679628, longitude: -90.4976054),
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
            phone: "(618) 215-5703",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.690675, longitude: -89.9736355),
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
            coordinate: CLLocationCoordinate2D(latitude: 38.6735435, longitude: -90.4204072),
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
            coordinate: CLLocationCoordinate2D(latitude: 38.592339, longitude: -90.562759),
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
            coordinate: CLLocationCoordinate2D(latitude: 38.212509, longitude: -90.3965979),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12617/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12617/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // First Capitol Total Access location (Hospital ID 12611)
        Facility(
            id: "total-access-12611",
            name: "Total Access Urgent Care - First Capitol",
            address: "2138 First Capitol Drive",
            city: "Saint Charles",
            state: "MO",
            zipCode: "63301",
            phone: "(636) 534-4498",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7820652, longitude: -90.5049265),
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
            coordinate: CLLocationCoordinate2D(latitude: 38.7984905, longitude: -90.3260814),
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
            city: "Saint Louis",
            state: "MO",
            zipCode: "63139",
            phone: "(314) 696-2341",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6178478, longitude: -90.2872087),
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
            coordinate: CLLocationCoordinate2D(latitude: 38.5658932, longitude: -90.2781801),
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
            city: "Lake Saint Louis",
            state: "MO",
            zipCode: "63367",
            phone: "(636) 265-6230",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.765825, longitude: -90.7824406),
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
            coordinate: CLLocationCoordinate2D(latitude: 38.8052981, longitude: -90.7003643),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12620/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12620/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // O'Fallon South Total Access location (Hospital ID 12618)
        Facility(
            id: "total-access-12618",
            name: "Total Access Urgent Care - O'Fallon South",
            address: "4201 Highway K",
            city: "O'Fallon",
            state: "MO",
            zipCode: "63368",
            phone: "(636) 294-8540",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7246358, longitude: -90.6987645),
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
            phone: "(618) 206-1032",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5720968, longitude: -89.9298124),
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
            city: "Oakville",
            state: "MO",
            zipCode: "63129",
            phone: "(314) 343-0056",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.4845585, longitude: -90.3039474),
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
            coordinate: CLLocationCoordinate2D(latitude: 38.6868011, longitude: -90.3573034),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12623/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12623/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Richmond Heights Total Access location (Hospital ID 12601)
        Facility(
            id: "total-access-12601",
            name: "Total Access Urgent Care - Richmond Heights",
            address: "1005 South Big Bend Boulevard",
            city: "Saint Louis",
            state: "MO",
            zipCode: "63117",
            phone: "(314) 449-8677",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6345842, longitude: -90.318935),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12601/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12601/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // Rock Hill Total Access location (Hospital ID 12626)
        Facility(
            id: "total-access-12626",
            name: "Total Access Urgent Care - Rock Hill",
            address: "9556 Manchester Road",
            city: "Saint Louis",
            state: "MO",
            zipCode: "63119",
            phone: "(314) 373-5740",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6087771, longitude: -90.3656043),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12626/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12626/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // South County Total Access location (Hospital ID 12605)
        Facility(
            id: "total-access-12605",
            name: "Total Access Urgent Care - South County",
            address: "12616 Lamplighter Square",
            city: "Saint Louis",
            state: "MO",
            zipCode: "63128",
            phone: "(314) 669-9193",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5044217, longitude: -90.3780724),
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
            city: "Saint Charles",
            state: "MO",
            zipCode: "63376",
            phone: "(636) 477-6344",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7907394, longitude: -90.5661609),
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
            city: "Saint Louis",
            state: "MO",
            zipCode: "63109",
            phone: "(314) 899-9344",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5884304, longitude: -90.3093765),
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
            city: "Saint Peters",
            state: "MO",
            zipCode: "63376",
            phone: "(636) 224-3208",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7862506, longitude: -90.6256561),
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
            city: "Saint Louis",
            state: "MO",
            zipCode: "63118",
            phone: "(314) 696-2178",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6021486, longitude: -90.242076),
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
            coordinate: CLLocationCoordinate2D(latitude: 38.5971668, longitude: -90.4833397),
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
            city: "Saint Louis",
            state: "MO",
            zipCode: "63122",
            phone: "(636) 529-8411",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5680391, longitude: -90.4754887),
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
            coordinate: CLLocationCoordinate2D(latitude: 38.5397942, longitude: -91.0050426),
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
            coordinate: CLLocationCoordinate2D(latitude: 38.8173991, longitude: -90.8757437),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12609/waits",
            websiteURL: "https://www.clockwisemd.com/hospitals/12609/visits/new",
            operatingHours: .standardUrgentCare
        ),
        
        // MERCY GO HEALTH URGENT CARE LOCATIONS
        
        // Hampton Village Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-hampton-village",
            name: "Hampton Village",
            address: "4260 Hampton Ave",
            city: "St. Louis",
            state: "MO",
            zipCode: "63109",
            phone: "(314) 282-6323",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5915826, longitude: -90.2938971),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271772110&latitude=38.591569&longitude=-90.293861&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/hampton-village",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Maplewood Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-maplewood",
            name: "Maplewood",
            address: "2015 Maplewood Commons Dr",
            city: "St Louis",
            state: "MO",
            zipCode: "63143",
            phone: "(314) 293-4023",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.62084, longitude: -90.3335511),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271102110&latitude=38.620837&longitude=-90.333624&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/maplewood",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Clayton Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-clayton",
            name: "Clayton",
            address: "8321 Maryland Ave",
            city: "Clayton",
            state: "MO",
            zipCode: "63105",
            phone: "(314) 626-8010",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.653369, longitude: -90.347072),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271142110&latitude=38.653369&longitude=-90.347072&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/clayton",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Kirkwood Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-kirkwood",
            name: "Kirkwood",
            address: "10700 Manchester Rd, Ste E",
            city: "Kirkwood",
            state: "MO",
            zipCode: "63122",
            phone: "(314) 455-7088",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.600074, longitude: -90.4042254),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271012110&latitude=38.600092&longitude=-90.404309&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/kirkwood",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Crestwood Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-crestwood",
            name: "Crestwood",
            address: "9551 Watson Rd",
            city: "Crestwood",
            state: "MO",
            zipCode: "63126",
            phone: "(314) 501-1826",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5578676, longitude: -90.3794057),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271762110&latitude=38.557861&longitude=-90.379417&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/crestwood",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Creve Coeur Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-creve-coeur",
            name: "Creve Coeur",
            address: "11445 Olive Blvd",
            city: "Creve Coeur",
            state: "MO",
            zipCode: "63141",
            phone: "(314) 428-9543",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6728643, longitude: -90.4339883),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271022111&latitude=38.672871&longitude=-90.433949&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/creve-coeur",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Florissant Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-florissant",
            name: "Florissant",
            address: "3433 N Hwy 67",
            city: "Florissant",
            state: "MO",
            zipCode: "63033",
            phone: "(314) 720-4380",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.8135432, longitude: -90.2917781),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271722110&latitude=38.813866&longitude=-90.291763&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/florissant",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Des Peres Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-des-peres",
            name: "Des Peres",
            address: "13275 Manchester Rd, Suite 101",
            city: "Des Peres",
            state: "MO",
            zipCode: "63131",
            phone: "(314) 396-8222",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6023504, longitude: -90.4657508),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271092110&latitude=38.602091&longitude=-90.465555&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/des-peres",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Oakville Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-oakville",
            name: "Oakville",
            address: "5640 Telegraph Rd, Ste C",
            city: "St. Louis",
            state: "MO",
            zipCode: "63129",
            phone: "(314) 293-4413",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.4670748, longitude: -90.3029176),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271162110&latitude=38.46732&longitude=-90.30299&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/oakville",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Fenton Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-fenton",
            name: "Fenton",
            address: "676 Gravois Bluffs Blvd, Suite A1",
            city: "Fenton",
            state: "MO",
            zipCode: "63026",
            phone: "(636) 492-2245",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5073371, longitude: -90.4418825),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271332110&latitude=38.507286&longitude=-90.441916&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/fenton",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Manchester Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-manchester",
            name: "Manchester",
            address: "409 Lafayette Center",
            city: "Ballwin",
            state: "MO",
            zipCode: "63011",
            phone: "(636) 707-0764",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.595659, longitude: -90.521639),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271032111&latitude=38.595659&longitude=-90.521639&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/manchester-mo",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Chesterfield Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-chesterfield",
            name: "Chesterfield",
            address: "1722 Clarkson Rd",
            city: "Chesterfield",
            state: "MO",
            zipCode: "63017",
            phone: "(636) 206-2665",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6422419, longitude: -90.5661633),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271072110&latitude=38.64223&longitude=-90.566168&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/chesterfield",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Saint Charles Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-saint-charles",
            name: "Saint Charles",
            address: "2031 Zumbehl Rd",
            city: "St. Charles",
            state: "MO",
            zipCode: "63303",
            phone: "(636) 206-2690",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.783069, longitude: -90.5348721),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271082110&latitude=38.78297&longitude=-90.534918&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/st-charles",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Imperial Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-imperial",
            name: "Imperial",
            address: "1125 Imperial Main St",
            city: "Imperial",
            state: "MO",
            zipCode: "63052",
            phone: "(636) 206-8051",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.3700939, longitude: -90.3811456),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?latitude=38.370092&longitude=-90.381148&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/imperial",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Cottleville Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-cottleville",
            name: "Cottleville",
            address: "6167 Mid Rivers Mall Dr",
            city: "St. Peters",
            state: "MO",
            zipCode: "63304",
            phone: "(636) 364-4990",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7418938, longitude: -90.6361775),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271172110&latitude=38.741944&longitude=-90.636188&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/cottleville",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Eureka Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-eureka",
            name: "Eureka",
            address: "20 The Legends Pkwy",
            city: "Eureka",
            state: "MO",
            zipCode: "63025",
            phone: "(636) 549-8509",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.495944, longitude: -90.62709),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?latitude=38.495944&longitude=-90.62709&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/eureka",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // O'Fallon Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-ofallon",
            name: "O'Fallon",
            address: "2991 State Hwy K",
            city: "O'Fallon",
            state: "MO",
            zipCode: "63368",
            phone: "(636) 435-2333",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7573681, longitude: -90.7038291),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271122110&latitude=38.757368&longitude=-90.703829&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/ofallon",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Lake Saint Louis Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-lake-saint-louis",
            name: "Lake Saint Louis",
            address: "6460 Ronald Reagan Drive",
            city: "Lake Saint Louis",
            state: "MO",
            zipCode: "63367",
            phone: "(636) 205-9613",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7646633, longitude: -90.785675),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271322110&latitude=38.764834&longitude=-90.786693&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/lake-st-louis",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Festus Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-festus",
            name: "Festus",
            address: "660A S Truman Blvd",
            city: "Festus",
            state: "MO",
            zipCode: "63028",
            phone: "(636) 206-8049",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.21226, longitude: -90.390725),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?latitude=38.21226&longitude=-90.390725&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/festus",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Wentzville Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-wentzville",
            name: "Wentzville",
            address: "1111 W Pearce Blvd",
            city: "Wentzville",
            state: "MO",
            zipCode: "63385",
            phone: "(636) 856-5362",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.8108186, longitude: -90.8706043),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=271742110&latitude=38.811278&longitude=-90.87051&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/wentzville",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Washington Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-washington",
            name: "Washington",
            address: "555 Washington Square Shopping Center",
            city: "Washington",
            state: "MO",
            zipCode: "63090",
            phone: "(636) 392-2209",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.538205, longitude: -91.003986),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?latitude=38.538205&longitude=-91.003986&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/washington",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Union Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-union",
            name: "Union",
            address: "39 Silo Drive",
            city: "Union",
            state: "MO",
            zipCode: "63084",
            phone: "(636) 234-3022",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.4332274, longitude: -90.9753883),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?latitude=38.433318&longitude=-90.975217&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/union",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Lincoln Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-lincoln",
            name: "Lincoln",
            address: "1000 E Cherry Street",
            city: "Troy",
            state: "MO",
            zipCode: "63379",
            phone: "(636) 528-3495",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.983242, longitude: -90.963305),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=202065110&latitude=38.983242&longitude=-90.963305&isGoHealthLocation=false",
            websiteURL: "https://www.mercy.net/practice/mercy-urgent-care-lincoln/",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // East Sunshine Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-east-sunshine",
            name: "East Sunshine",
            address: "3233 E Sunshine St, Ste 100",
            city: "Springfield",
            state: "MO",
            zipCode: "65804",
            phone: "(417) 812-8149",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 37.1809378, longitude: -93.2301356),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=471042110&latitude=37.180938&longitude=-93.230136&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-springfield/locations/east-sunshine",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // West Sunshine Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-west-sunshine",
            name: "West Sunshine",
            address: "303 W Sunshine St",
            city: "Springfield",
            state: "MO",
            zipCode: "65807",
            phone: "(417) 986-0452",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 37.1824985, longitude: -93.2939906),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=471062110&latitude=37.182499&longitude=-93.293991&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-springfield/locations/west-sunshine",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // E. Battlefield Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-e-battlefield",
            name: "E. Battlefield",
            address: "900 E Battlefield Rd, Ste 124",
            city: "Springfield",
            state: "MO",
            zipCode: "65807",
            phone: "(417) 986-1289",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 37.1588352, longitude: -93.2826719),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=471012110&latitude=37.159716&longitude=-93.283318&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-springfield/locations/east-battlefield",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),
        
        // Stone's Corner Mercy-GoHealth location
        Facility(
            id: "mercy-gohealth-stones-corner",
            name: "Mercy GoHealth - Stone's Corner",
            address: "6055 N Main Street Rd",
            city: "Webb City",
            state: "MO",
            zipCode: "64870",
            phone: "(417) 717-8846",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 37.1435354, longitude: -94.5113091),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://www.mercy.net/content/mercy/us/en.waitTime?departmentId=471092110&latitude=37.143563&longitude=-94.511307&isGoHealthLocation=true",
            websiteURL: "https://www.gohealthuc.com/mercy-joplin/locations/stones-corner",
            operatingHours: OperatingHours(
                monday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                tuesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                wednesday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                thursday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                friday: OperatingHours.DayHours(open: "08:00", close: "20:00"),
                saturday: OperatingHours.DayHours(open: "09:00", close: "17:00"),
                sunday: OperatingHours.DayHours(open: "09:00", close: "17:00")
            )
        ),

        // ST. LUKE'S URGENT CARE + WALK-IN LOCATIONS

        // Eureka St. Luke's Walk-In Clinic
        Facility(
            id: "st-lukes-walk-in-eureka",
            name: "St. Luke's Walk-In Clinic - Eureka",
            address: "103 Hilltop Village Center Drive",
            city: "Eureka",
            state: "MO",
            zipCode: "63025",
            phone: "(314) 864-7839",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.50629107835506, longitude: -90.64261326057346),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://schedule.stlukes-stl.com/0saml2/1saml2/schedule/previewLocationSlots?test=false&patientType=new&fhirLocationId=4379404195",
            websiteURL: "https://www.stlukes-stl.com/locations/st-lukes-walk-in-clinic-eureka",
            operatingHours: .standardUrgentCare
        ),

        // Chesterfield St. Luke's Urgent Care
        Facility(
            id: "st-lukes-urgent-care-chesterfield",
            name: "St. Luke's Urgent Care Center - Chesterfield",
            address: "17421 Chesterfield Airport Rd",
            city: "Chesterfield",
            state: "MO",
            zipCode: "63005",
            phone: "(636) 685-7720",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.66901699967911, longitude: -90.60921698940379),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://schedule.stlukes-stl.com/0saml2/1saml2/schedule/previewLocationSlots?test=false&patientType=new&fhirLocationId=276372382",
            websiteURL: "https://www.stlukes-stl.com/locations/st-lukes-urgent-care-center-chesterfield",
            operatingHours: .standardUrgentCare
        ),

        // Creve Coeur St. Luke's Urgent Care
        Facility(
            id: "st-lukes-urgent-care-creve-coeur",
            name: "St. Luke's Urgent Care Center - Creve Coeur",
            address: "11550 Olive Blvd",
            city: "Creve Coeur",
            state: "MO",
            zipCode: "63141",
            phone: "(314) 542-7690",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.67075037298327, longitude: -90.4372181894037),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://schedule.stlukes-stl.com/0saml2/1saml2/schedule/previewLocationSlots?test=false&patientType=new&fhirLocationId=40462355",
            websiteURL: "https://www.stlukes-stl.com/locations/st-lukes-urgent-care-center-creve-coeur",
            operatingHours: .standardUrgentCare
        ),

        // Ellisville St. Luke's Urgent Care
        Facility(
            id: "st-lukes-urgent-care-ellisville",
            name: "St. Luke's Urgent Care Center - Ellisville",
            address: "233 Clarkson Rd",
            city: "Ellisville",
            state: "MO",
            zipCode: "63011",
            phone: "(636) 256-8644",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.59964806890928, longitude: -90.58523386057024),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://schedule.stlukes-stl.com/0saml2/1saml2/schedule/previewLocationSlots?test=false&patientType=new&fhirLocationId=13870511",
            websiteURL: "https://www.stlukes-stl.com/locations/st-lukes-urgent-care-center-ellisville",
            operatingHours: .standardUrgentCare
        ),

        // Arnold St. Luke's Urgent Care
        Facility(
            id: "st-lukes-urgent-care-arnold",
            name: "St. Luke's Urgent Care Center - Arnold",
            address: "832 Arnold Commons",
            city: "Arnold",
            state: "MO",
            zipCode: "63010",
            phone: "(636) 685-7899",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.43847066318515, longitude: -90.38260285872444),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://schedule.stlukes-stl.com/0saml2/1saml2/schedule/previewLocationSlots?test=false&patientType=new&fhirLocationId=928197489",
            websiteURL: "https://www.stlukes-stl.com/locations/st-lukes-urgent-care-center-arnold",
            operatingHours: .standardUrgentCare
        ),

        // Fenton St. Luke's Urgent Care
        Facility(
            id: "st-lukes-urgent-care-fenton",
            name: "St. Luke's Urgent Care Center - Fenton",
            address: "774 Gravois Bluffs Blvd, Suite A",
            city: "Fenton",
            state: "MO",
            zipCode: "63026",
            phone: "(636) 343-5223",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.50293769465144, longitude: -90.45076343173766),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://schedule.stlukes-stl.com/0saml2/1saml2/schedule/previewLocationSlots?test=false&patientType=new&fhirLocationId=12597628",
            websiteURL: "https://www.stlukes-stl.com/locations/st-lukes-urgent-care-center-fenton",
            operatingHours: .standardUrgentCare
        ),

        // Ladue St. Luke's Urgent Care
        Facility(
            id: "st-lukes-urgent-care-ladue",
            name: "St. Luke's Urgent Care Center - Ladue",
            address: "8857 Ladue Rd",
            city: "St. Louis",
            state: "MO",
            zipCode: "63124",
            phone: "(314) 576-8189",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.65417013390694, longitude: -90.35204214522473),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://schedule.stlukes-stl.com/0saml2/1saml2/schedule/previewLocationSlots?test=false&patientType=new&fhirLocationId=187372068",
            websiteURL: "https://www.stlukes-stl.com/locations/st-lukes-urgent-care-center-ladue",
            operatingHours: .standardUrgentCare
        ),

        // O'Fallon St. Luke's Urgent Care
        Facility(
            id: "st-lukes-urgent-care-ofallon",
            name: "St. Luke's Urgent Care Center - O'Fallon",
            address: "5551 WingHaven Blvd, Suite 100",
            city: "O'Fallon",
            state: "MO",
            zipCode: "63368",
            phone: "(636) 695-2500",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.75261154392055, longitude: -90.7477273452213),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://schedule.stlukes-stl.com/0saml2/1saml2/schedule/previewLocationSlots?test=false&patientType=new&fhirLocationId=13870513",
            websiteURL: "https://www.stlukes-stl.com/locations/st-lukes-urgent-care-center-ofallon",
            operatingHours: .standardUrgentCare
        ),

        // Des Peres St. Luke's Walk-In Clinic
        Facility(
            id: "st-lukes-walk-in-des-peres",
            name: "St. Luke's Walk-In Clinic - Des Peres",
            address: "12304 Manchester Rd",
            city: "Des Peres",
            state: "MO",
            zipCode: "63131",
            phone: "(314) 965-6871",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.60299232320302, longitude: -90.4419459028983),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://schedule.stlukes-stl.com/0saml2/1saml2/schedule/previewLocationSlots?test=false&patientType=new&fhirLocationId=4853605163",
            websiteURL: "https://www.stlukes-stl.com/locations/st-lukes-walk-in-clinic-des-peres",
            operatingHours: .standardUrgentCare
        ),
        
        // AFC Urgent Care Sedalia (Hospital ID 5955)
        Facility(
            id: "afc-sedalia-5955",
            name: "Sedalia",
            address: "115 W Broadway Blvd, Suite 100",
            city: "Sedalia",
            state: "MO",
            zipCode: "65301-5708",
            phone: "(660) 951-1091",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7038573, longitude: -93.2291603),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/5955/waits",
            websiteURL: "https://www.afcurgentcare.com/sedalia/",
            operatingHours: .standardUrgentCare
        )
        // Expanded urgent-care dataset with Total Access, Mercy-GoHealth, St. Luke's, and AFC locations.
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
