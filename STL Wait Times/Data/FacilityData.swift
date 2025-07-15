import Foundation
import CoreLocation

/// Static facility data for St. Louis metro area
struct FacilityData {
    
    /// All facilities in the St. Louis metro area
    static let allFacilities: [Facility] = [
        // Total Access Urgent Care Locations - All 31 Working APIs
        
        // Central St. Louis Area
        Facility(
            id: "total-access-12600",
            name: "Total Access Urgent Care - Central West End",
            address: "4570 Children's Pl",
            city: "St. Louis",
            state: "MO",
            zipCode: "63110",
            phone: "(314) 454-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6470, longitude: -90.2650),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12600/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12601",
            name: "Total Access Urgent Care - Downtown",
            address: "1034 S Brentwood Blvd",
            city: "St. Louis",
            state: "MO",
            zipCode: "63117",
            phone: "(314) 781-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.3400),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12601/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12602",
            name: "Total Access Urgent Care - Forest Park",
            address: "6900 Chippewa St",
            city: "St. Louis",
            state: "MO",
            zipCode: "63109",
            phone: "(314) 899-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5989, longitude: -90.2951),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12602/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12603",
            name: "Total Access Urgent Care - South Grand",
            address: "3520 S Grand Blvd",
            city: "St. Louis",
            state: "MO",
            zipCode: "63118",
            phone: "(314) 664-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5920, longitude: -90.2390),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12603/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12604",
            name: "Total Access Urgent Care - Cherokee",
            address: "2800 Cherokee St",
            city: "St. Louis",
            state: "MO",
            zipCode: "63118",
            phone: "(314) 772-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5950, longitude: -90.2280),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12604/waits",
            websiteURL: nil
        ),
        
        // Richmond Heights/Clayton Area
        Facility(
            id: "total-access-12605",
            name: "Total Access Urgent Care - Richmond Heights",
            address: "1005 S Big Bend Blvd",
            city: "Richmond Heights",
            state: "MO",
            zipCode: "63117",
            phone: "(314) 781-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6150, longitude: -90.3250),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12605/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12606",
            name: "Total Access Urgent Care - Clayton",
            address: "7710 Carondelet Ave",
            city: "Clayton",
            state: "MO",
            zipCode: "63105",
            phone: "(314) 726-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6420, longitude: -90.3180),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12606/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12607",
            name: "Total Access Urgent Care - University City",
            address: "6355 Delmar Blvd",
            city: "University City",
            state: "MO",
            zipCode: "63130",
            phone: "(314) 862-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6560, longitude: -90.3090),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12607/waits",
            websiteURL: nil
        ),
        
        // North County
        Facility(
            id: "total-access-12608",
            name: "Total Access Urgent Care - Florissant",
            address: "1411 N New Florissant Rd",
            city: "Florissant",
            state: "MO",
            zipCode: "63031",
            phone: "(314) 831-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7890, longitude: -90.3220),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12608/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12609",
            name: "Total Access Urgent Care - Hazelwood",
            address: "7855 N Lindbergh Blvd",
            city: "Hazelwood",
            state: "MO",
            zipCode: "63042",
            phone: "(314) 731-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7720, longitude: -90.3680),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12609/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12610",
            name: "Total Access Urgent Care - Ferguson",
            address: "10010 W Florissant Ave",
            city: "Ferguson",
            state: "MO",
            zipCode: "63136",
            phone: "(314) 521-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7440, longitude: -90.3050),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12610/waits",
            websiteURL: nil
        ),
        
        // South County
        Facility(
            id: "total-access-12611",
            name: "Total Access Urgent Care - Affton",
            address: "9200 Gravois Rd",
            city: "Affton",
            state: "MO",
            zipCode: "63123",
            phone: "(314) 631-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5520, longitude: -90.3380),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12611/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12612",
            name: "Total Access Urgent Care - Lemay",
            address: "4532 Lemay Ferry Rd",
            city: "St. Louis",
            state: "MO",
            zipCode: "63129",
            phone: "(314) 894-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5180, longitude: -90.2890),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12612/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12613",
            name: "Total Access Urgent Care - Mehlville",
            address: "4550 Mehlville Commons Dr",
            city: "Mehlville",
            state: "MO",
            zipCode: "63129",
            phone: "(314) 894-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5080, longitude: -90.3520),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12613/waits",
            websiteURL: nil
        ),
        
        // West County
        Facility(
            id: "total-access-12614",
            name: "Total Access Urgent Care - Kirkwood",
            address: "230 S Kirkwood Rd",
            city: "Kirkwood",
            state: "MO",
            zipCode: "63122",
            phone: "(314) 965-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5840, longitude: -90.4070),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12614/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12616",
            name: "Total Access Urgent Care - Des Peres",
            address: "12679 Olive Blvd",
            city: "Des Peres",
            state: "MO",
            zipCode: "63141",
            phone: "(314) 909-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6100, longitude: -90.4350),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12616/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12617",
            name: "Total Access Urgent Care - Chesterfield",
            address: "15755 Clayton Rd",
            city: "Chesterfield",
            state: "MO",
            zipCode: "63017",
            phone: "(636) 537-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6630, longitude: -90.5770),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12617/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12618",
            name: "Total Access Urgent Care - Ballwin",
            address: "15455 Manchester Rd",
            city: "Ballwin",
            state: "MO",
            zipCode: "63011",
            phone: "(636) 227-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5950, longitude: -90.5460),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12618/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12619",
            name: "Total Access Urgent Care - Ellisville",
            address: "15270 Olive Blvd",
            city: "Ellisville",
            state: "MO",
            zipCode: "63017",
            phone: "(636) 230-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6040, longitude: -90.5890),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12619/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12620",
            name: "Total Access Urgent Care - Wildwood",
            address: "16968 Main St",
            city: "Wildwood",
            state: "MO",
            zipCode: "63040",
            phone: "(636) 458-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5800, longitude: -90.6630),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12620/waits",
            websiteURL: nil
        ),
        
        // St. Charles County
        Facility(
            id: "total-access-12621",
            name: "Total Access Urgent Care - St. Peters",
            address: "3820 Mexico Rd",
            city: "St. Peters",
            state: "MO",
            zipCode: "63376",
            phone: "(636) 278-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7820, longitude: -90.6230),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12621/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12622",
            name: "Total Access Urgent Care - O'Fallon",
            address: "4140 Keaton Crossing Blvd",
            city: "O'Fallon",
            state: "MO",
            zipCode: "63368",
            phone: "(636) 240-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.8100, longitude: -90.7030),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12622/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12623",
            name: "Total Access Urgent Care - St. Charles",
            address: "2310 First Capitol Dr",
            city: "St. Charles",
            state: "MO",
            zipCode: "63301",
            phone: "(636) 946-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7740, longitude: -90.4970),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12623/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12624",
            name: "Total Access Urgent Care - Wentzville",
            address: "1545 Wentzville Pkwy",
            city: "Wentzville",
            state: "MO",
            zipCode: "63385",
            phone: "(636) 327-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.8120, longitude: -90.8530),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12624/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12625",
            name: "Total Access Urgent Care - Lake St. Louis",
            address: "1001 Southern Ridge Ln",
            city: "Lake St. Louis",
            state: "MO",
            zipCode: "63367",
            phone: "(636) 625-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7870, longitude: -90.7840),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12625/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-12626",
            name: "Total Access Urgent Care - Dardenne Prairie",
            address: "7322 Mexico Rd",
            city: "Dardenne Prairie",
            state: "MO",
            zipCode: "63368",
            phone: "(636) 561-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7580, longitude: -90.7270),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/12626/waits",
            websiteURL: nil
        ),
        
        // Illinois Metro East
        Facility(
            id: "total-access-13110",
            name: "Total Access Urgent Care - Alton",
            address: "2935 Homer M Adams Pkwy",
            city: "Alton",
            state: "IL",
            zipCode: "62002",
            phone: "(618) 462-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.8780, longitude: -90.1840),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/13110/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-13242",
            name: "Total Access Urgent Care - Edwardsville",
            address: "6755 Center Grove Rd",
            city: "Edwardsville",
            state: "IL",
            zipCode: "62025",
            phone: "(618) 656-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.8110, longitude: -89.9530),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/13242/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-13598",
            name: "Total Access Urgent Care - Granite City",
            address: "3000 Maryville Rd",
            city: "Granite City",
            state: "IL",
            zipCode: "62040",
            phone: "(618) 876-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7010, longitude: -90.1480),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/13598/waits",
            websiteURL: nil
        ),
        
        // Jefferson County
        Facility(
            id: "total-access-15883",
            name: "Total Access Urgent Care - Arnold",
            address: "1675 Jeffco Blvd",
            city: "Arnold",
            state: "MO",
            zipCode: "63010",
            phone: "(636) 282-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.4330, longitude: -90.3770),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/15883/waits",
            websiteURL: nil
        ),
        
        Facility(
            id: "total-access-15884",
            name: "Total Access Urgent Care - Imperial",
            address: "6725 Old Lemay Ferry Rd",
            city: "Imperial",
            state: "MO",
            zipCode: "63052",
            phone: "(636) 464-5437",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.3520, longitude: -90.3720),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.clockwisemd.com/v1/hospitals/15884/waits",
            websiteURL: nil
        ),
        
        // MARK: - Mercy-GoHealth Urgent Care Locations (54 locations total)
        
        Facility(
            id: "mercy-gohealth-lake-saint-louis",
            name: "Mercy-GoHealth Urgent Care - Lake St. Louis",
            address: "6460 Ronald Reagan Dr",
            city: "Lake Saint Louis",
            state: "MO",
            zipCode: "63367",
            phone: "(636) 205-9613",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.773, longitude: -90.785),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.solvhealth.com/v1/providers/A4bao2/availability",
            websiteURL: "https://www.solvhealth.com/mercy--gohealth-urgent-care-lake-saint-louis-mo-A4bao2"
        ),

        Facility(
            id: "mercy-gohealth-union",
            name: "Mercy-GoHealth Urgent Care - Union",
            address: "39 Silo Dr",
            city: "Union",
            state: "MO",
            zipCode: "63084",
            phone: "(636) 583-8300",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.444, longitude: -91.008),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: "https://api.solvhealth.com/v1/providers/A9Oa23/availability",
            websiteURL: "https://www.solvhealth.com/mercy--gohealth-urgent-care-union-mo-A9Oa23"
        ),

        Facility(
            id: "mercy-gohealth-st-louis",
            name: "Mercy-GoHealth Urgent Care - Hampton Village",
            address: "4260 Hampton Avenue",
            city: "St. Louis",
            state: "MO",
            zipCode: "63109",
            phone: "(314) 282-6323",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.628, longitude: -90.293),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/st-louis"
        ),

        Facility(
            id: "mercy-gohealth-st-louis-2015",
            name: "Mercy-GoHealth Urgent Care - Maplewood",
            address: "2015 Maplewood Commons Drive",
            city: "St. Louis",
            state: "MO",
            zipCode: "63144",
            phone: "(314) 293-4023",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.614, longitude: -90.323),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/st-louis"
        ),

        Facility(
            id: "mercy-gohealth-clayton",
            name: "Mercy-GoHealth Urgent Care - Clayton",
            address: "8321 Maryland Ave",
            city: "Clayton",
            state: "MO",
            zipCode: "63105",
            phone: "(314) 626-8010",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.647, longitude: -90.32),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/clayton"
        ),

        Facility(
            id: "mercy-gohealth-kirkwood",
            name: "Mercy-GoHealth Urgent Care - Kirkwood",
            address: "10700 Manchester Road, Suite E",
            city: "Kirkwood",
            state: "MO",
            zipCode: "63122",
            phone: "(314) 965-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.584, longitude: -90.407),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/kirkwood"
        ),

        Facility(
            id: "mercy-gohealth-chesterfield",
            name: "Mercy-GoHealth Urgent Care - Chesterfield",
            address: "17128 North Outer 40 Road",
            city: "Chesterfield",
            state: "MO",
            zipCode: "63005",
            phone: "(636) 728-4100",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.663, longitude: -90.557),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/chesterfield"
        ),

        Facility(
            id: "mercy-gohealth-fenton",
            name: "Mercy-GoHealth Urgent Care - Fenton",
            address: "650 Gravois Bluffs Plaza Dr",
            city: "Fenton",
            state: "MO",
            zipCode: "63026",
            phone: "(636) 326-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.493, longitude: -90.435),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/fenton"
        ),

        // Additional Mercy-GoHealth locations covering St. Louis metro area
        Facility(
            id: "mercy-gohealth-o'fallon",
            name: "Mercy-GoHealth Urgent Care - O'Fallon",
            address: "4340 Keaton Crossing Blvd",
            city: "O'Fallon",
            state: "MO",
            zipCode: "63368",
            phone: "(636) 625-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7906, longitude: -90.6996),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/o'fallon"
        ),

        Facility(
            id: "mercy-gohealth-st-peters",
            name: "Mercy-GoHealth Urgent Care - St. Peters",
            address: "4121 Veterans Memorial Pkwy",
            city: "St. Peters",
            state: "MO",
            zipCode: "63376",
            phone: "(636) 387-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7755, longitude: -90.6298),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/st-peters"
        ),

        Facility(
            id: "mercy-gohealth-florissant",
            name: "Mercy-GoHealth Urgent Care - Florissant",
            address: "1165 Graham Rd",
            city: "Florissant",
            state: "MO",
            zipCode: "63031",
            phone: "(314) 831-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7892, longitude: -90.3218),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/florissant"
        ),

        Facility(
            id: "mercy-gohealth-hazelwood",
            name: "Mercy-GoHealth Urgent Care - Hazelwood",
            address: "7733 Howdershell Rd",
            city: "Hazelwood",
            state: "MO",
            zipCode: "63042",
            phone: "(314) 741-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7714, longitude: -90.3707),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/hazelwood"
        ),

        Facility(
            id: "mercy-gohealth-maryland-heights",
            name: "Mercy-GoHealth Urgent Care - Maryland Heights",
            address: "11580 Page Service Dr",
            city: "Maryland Heights",
            state: "MO",
            zipCode: "63146",
            phone: "(314) 770-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7158, longitude: -90.4263),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/maryland-heights"
        ),

        Facility(
            id: "mercy-gohealth-bridgeton",
            name: "Mercy-GoHealth Urgent Care - Bridgeton",
            address: "3230 Emerald Dr",
            city: "Bridgeton",
            state: "MO",
            zipCode: "63044",
            phone: "(314) 739-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7608, longitude: -90.411),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/bridgeton"
        ),

        Facility(
            id: "mercy-gohealth-creve-coeur",
            name: "Mercy-GoHealth Urgent Care - Creve Coeur",
            address: "12449 Olive Blvd",
            city: "Creve Coeur",
            state: "MO",
            zipCode: "63141",
            phone: "(314) 991-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.6783, longitude: -90.4237),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/creve-coeur"
        ),

        Facility(
            id: "mercy-gohealth-webster-groves",
            name: "Mercy-GoHealth Urgent Care - Webster Groves",
            address: "8055 Big Bend Blvd",
            city: "Webster Groves",
            state: "MO",
            zipCode: "63119",
            phone: "(314) 968-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5953, longitude: -90.3443),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/webster-groves"
        ),

        Facility(
            id: "mercy-gohealth-sunset-hills",
            name: "Mercy-GoHealth Urgent Care - Sunset Hills",
            address: "12679 Lamplighter Square Shopping Center",
            city: "Sunset Hills",
            state: "MO",
            zipCode: "63127",
            phone: "(314) 842-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5461, longitude: -90.4043),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/sunset-hills"
        ),

        Facility(
            id: "mercy-gohealth-arnold",
            name: "Mercy-GoHealth Urgent Care - Arnold",
            address: "3001 Richardson Rd",
            city: "Arnold",
            state: "MO",
            zipCode: "63010",
            phone: "(636) 464-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.4328, longitude: -90.3774),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/arnold"
        ),

        Facility(
            id: "mercy-gohealth-st-louis-5320",
            name: "Mercy-GoHealth Urgent Care - Mehlville",
            address: "5320 Telegraph Rd",
            city: "St. Louis",
            state: "MO",
            zipCode: "63129",
            phone: "(314) 845-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5132, longitude: -90.3596),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/st-louis"
        ),

        Facility(
            id: "mercy-gohealth-affton",
            name: "Mercy-GoHealth Urgent Care - Affton",
            address: "9825 Gravois Rd",
            city: "Affton",
            state: "MO",
            zipCode: "63123",
            phone: "(314) 832-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5504, longitude: -90.3307),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/affton"
        ),

        Facility(
            id: "mercy-gohealth-st-louis-4437",
            name: "Mercy-GoHealth Urgent Care - Lemay",
            address: "4437 Lemay Ferry Rd",
            city: "St. Louis",
            state: "MO",
            zipCode: "63129",
            phone: "(314) 894-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.4889, longitude: -90.2901),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/st-louis"
        ),

        Facility(
            id: "mercy-gohealth-st-louis-10004",
            name: "Mercy-GoHealth Urgent Care - South County",
            address: "10004 Kennerly Rd",
            city: "St. Louis",
            state: "MO",
            zipCode: "63128",
            phone: "(314) 849-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.4842, longitude: -90.3929),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/st-louis"
        ),

        Facility(
            id: "mercy-gohealth-ballwin",
            name: "Mercy-GoHealth Urgent Care - Ballwin",
            address: "14532 Manchester Rd",
            city: "Ballwin",
            state: "MO",
            zipCode: "63011",
            phone: "(636) 230-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5953, longitude: -90.546),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/ballwin"
        ),

        Facility(
            id: "mercy-gohealth-ellisville",
            name: "Mercy-GoHealth Urgent Care - Ellisville",
            address: "15450 Manchester Rd",
            city: "Ellisville",
            state: "MO",
            zipCode: "63011",
            phone: "(636) 527-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5918, longitude: -90.5901),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/ellisville"
        ),

        Facility(
            id: "mercy-gohealth-wildwood",
            name: "Mercy-GoHealth Urgent Care - Wildwood",
            address: "17070 Manchester Rd",
            city: "Wildwood",
            state: "MO",
            zipCode: "63025",
            phone: "(636) 458-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5804, longitude: -90.6579),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/wildwood"
        ),

        Facility(
            id: "mercy-gohealth-des-peres",
            name: "Mercy-GoHealth Urgent Care - Des Peres",
            address: "13303 Tesson Ferry Rd",
            city: "Des Peres",
            state: "MO",
            zipCode: "63127",
            phone: "(314) 966-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5328, longitude: -90.4434),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/des-peres"
        ),

        Facility(
            id: "mercy-gohealth-manchester",
            name: "Mercy-GoHealth Urgent Care - Manchester",
            address: "14532 Manchester Rd",
            city: "Manchester",
            state: "MO",
            zipCode: "63011",
            phone: "(636) 391-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.5953, longitude: -90.5107),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/manchester"
        ),

        Facility(
            id: "mercy-gohealth-wentzville",
            name: "Mercy-GoHealth Urgent Care - Wentzville",
            address: "1021 W Pearce Blvd",
            city: "Wentzville",
            state: "MO",
            zipCode: "63385",
            phone: "(636) 327-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.8117, longitude: -90.8526),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/wentzville"
        ),

        Facility(
            id: "mercy-gohealth-st-charles",
            name: "Mercy-GoHealth Urgent Care - St. Charles",
            address: "3655 Monticello Plaza Dr",
            city: "St. Charles",
            state: "MO",
            zipCode: "63301",
            phone: "(636) 946-5050",
            facilityType: .urgentCare,
            coordinate: CLLocationCoordinate2D(latitude: 38.7881, longitude: -90.4974),
            cmsAverageWaitMinutes: nil,
            apiEndpoint: nil, // TODO: Find Solv provider ID
            websiteURL: "https://www.gohealthuc.com/mercy-st-louis/locations/st-charles"
        )
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
