import Foundation
import CoreLocation

/// Represents a healthcare facility (ED or Urgent Care)
struct Facility: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let phone: String
    let facilityType: FacilityType
    let coordinate: CLLocationCoordinate2D
    
    // CMS data for EDs
    let cmsAverageWaitMinutes: Int?
    
    // API endpoint for real-time data
    let apiEndpoint: String?
    
    // Website URL for web scraping fallback
    let websiteURL: String?
    
    // Computed properties
    var fullAddress: String {
        "\(address), \(city), \(state) \(zipCode)"
    }
    
    enum FacilityType: String, Codable, CaseIterable {
        case emergencyDepartment = "ED"
        case urgentCare = "UC"
        
        var displayName: String {
            switch self {
            case .emergencyDepartment:
                return "Emergency Department"
            case .urgentCare:
                return "Urgent Care"
            }
        }
    }
    
    // Custom coding keys to handle CLLocationCoordinate2D
    enum CodingKeys: String, CodingKey {
        case id, name, address, city, state, zipCode, phone, facilityType, cmsAverageWaitMinutes, apiEndpoint, websiteURL
        case latitude, longitude
    }
    
    init(id: String, name: String, address: String, city: String, state: String, zipCode: String, phone: String, facilityType: FacilityType, coordinate: CLLocationCoordinate2D, cmsAverageWaitMinutes: Int? = nil, apiEndpoint: String? = nil, websiteURL: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.phone = phone
        self.facilityType = facilityType
        self.coordinate = coordinate
        self.cmsAverageWaitMinutes = cmsAverageWaitMinutes
        self.apiEndpoint = apiEndpoint
        self.websiteURL = websiteURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        city = try container.decode(String.self, forKey: .city)
        state = try container.decode(String.self, forKey: .state)
        zipCode = try container.decode(String.self, forKey: .zipCode)
        phone = try container.decode(String.self, forKey: .phone)
        facilityType = try container.decode(FacilityType.self, forKey: .facilityType)
        cmsAverageWaitMinutes = try container.decodeIfPresent(Int.self, forKey: .cmsAverageWaitMinutes)
        apiEndpoint = try container.decodeIfPresent(String.self, forKey: .apiEndpoint)
        websiteURL = try container.decodeIfPresent(String.self, forKey: .websiteURL)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(city, forKey: .city)
        try container.encode(state, forKey: .state)
        try container.encode(zipCode, forKey: .zipCode)
        try container.encode(phone, forKey: .phone)
        try container.encode(facilityType, forKey: .facilityType)
        try container.encodeIfPresent(cmsAverageWaitMinutes, forKey: .cmsAverageWaitMinutes)
        try container.encodeIfPresent(apiEndpoint, forKey: .apiEndpoint)
        try container.encodeIfPresent(websiteURL, forKey: .websiteURL)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
    
    // Equatable conformance
    static func == (lhs: Facility, rhs: Facility) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.address == rhs.address &&
               lhs.city == rhs.city &&
               lhs.state == rhs.state &&
               lhs.zipCode == rhs.zipCode &&
               lhs.phone == rhs.phone &&
               lhs.facilityType == rhs.facilityType &&
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude &&
               lhs.cmsAverageWaitMinutes == rhs.cmsAverageWaitMinutes &&
               lhs.apiEndpoint == rhs.apiEndpoint &&
               lhs.websiteURL == rhs.websiteURL
    }
} 