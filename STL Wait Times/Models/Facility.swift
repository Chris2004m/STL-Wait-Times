import Foundation
import CoreLocation

/// Operating hours for a healthcare facility
struct OperatingHours: Codable, Equatable {
    let monday: DayHours?
    let tuesday: DayHours?
    let wednesday: DayHours?
    let thursday: DayHours?
    let friday: DayHours?
    let saturday: DayHours?
    let sunday: DayHours?
    
    struct DayHours: Codable, Equatable {
        let open: String  // Format: "08:00"
        let close: String // Format: "20:00"
        let isClosed: Bool
        
        init(open: String, close: String) {
            self.open = open
            self.close = close
            self.isClosed = false
        }
        
        static let closed = DayHours(open: "", close: "", isClosed: true)
        
        private init(open: String, close: String, isClosed: Bool) {
            self.open = open
            self.close = close
            self.isClosed = isClosed
        }
    }
    
    /// Standard Total Access Urgent Care hours (8 AM - 8 PM, 7 days a week)
    static let standardUrgentCare = OperatingHours(
        monday: DayHours(open: "08:00", close: "20:00"),
        tuesday: DayHours(open: "08:00", close: "20:00"),
        wednesday: DayHours(open: "08:00", close: "20:00"),
        thursday: DayHours(open: "08:00", close: "20:00"),
        friday: DayHours(open: "08:00", close: "20:00"),
        saturday: DayHours(open: "08:00", close: "20:00"),
        sunday: DayHours(open: "08:00", close: "20:00")
    )
    
    /// Emergency departments (24/7)
    static let emergency24x7 = OperatingHours(
        monday: DayHours(open: "00:00", close: "23:59"),
        tuesday: DayHours(open: "00:00", close: "23:59"),
        wednesday: DayHours(open: "00:00", close: "23:59"),
        thursday: DayHours(open: "00:00", close: "23:59"),
        friday: DayHours(open: "00:00", close: "23:59"),
        saturday: DayHours(open: "00:00", close: "23:59"),
        sunday: DayHours(open: "00:00", close: "23:59")
    )
    
    /// Get hours for a specific day of the week (1 = Sunday, 2 = Monday, etc.)
    func hours(for weekday: Int) -> DayHours? {
        switch weekday {
        case 1: return sunday
        case 2: return monday
        case 3: return tuesday
        case 4: return wednesday
        case 5: return thursday
        case 6: return friday
        case 7: return saturday
        default: return nil
        }
    }
    
    /// Check if facility is currently open
    func isOpen(at date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        guard let dayHours = hours(for: weekday), !dayHours.isClosed else {
            return false
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let currentTime = timeFormatter.string(from: date)
        
        return currentTime >= dayHours.open && currentTime <= dayHours.close
    }
}

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
    
    // Operating hours
    let operatingHours: OperatingHours?
    
    // Computed properties
    var fullAddress: String {
        "\(address), \(city), \(state) \(zipCode)"
    }
    
    /// Check if facility is currently open based on operating hours
    var isCurrentlyOpen: Bool {
        guard let hours = operatingHours else {
            // If no operating hours defined, assume open for emergency departments, closed for urgent care
            return facilityType == .emergencyDepartment
        }
        return hours.isOpen()
    }
    
    /// Get current status string ("Open" or "Closed")
    var statusString: String {
        return isCurrentlyOpen ? "Open" : "Closed"
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
        case id, name, address, city, state, zipCode, phone, facilityType, cmsAverageWaitMinutes, apiEndpoint, websiteURL, operatingHours
        case latitude, longitude
    }
    
    init(id: String, name: String, address: String, city: String, state: String, zipCode: String, phone: String, facilityType: FacilityType, coordinate: CLLocationCoordinate2D, cmsAverageWaitMinutes: Int? = nil, apiEndpoint: String? = nil, websiteURL: String? = nil, operatingHours: OperatingHours? = nil) {
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
        self.operatingHours = operatingHours
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
        operatingHours = try container.decodeIfPresent(OperatingHours.self, forKey: .operatingHours)
        
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
        try container.encodeIfPresent(operatingHours, forKey: .operatingHours)
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
               lhs.websiteURL == rhs.websiteURL &&
               lhs.operatingHours == rhs.operatingHours
    }
} 