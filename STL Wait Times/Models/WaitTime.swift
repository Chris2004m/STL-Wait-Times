import Foundation

/// Represents wait time data for a healthcare facility
struct WaitTime: Identifiable {
    let id = UUID()
    let facilityId: String
    let waitMinutes: Int
    let patientsInLine: Int
    let lastUpdated: Date
    let nextAvailableSlot: Int
    
    var displayText: String {
        if waitMinutes == 0 {
            return "No wait"
        } else if waitMinutes < 60 {
            return "\(waitMinutes) min"
        } else {
            let hours = waitMinutes / 60
            let minutes = waitMinutes % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
    
    var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > 300 // 5 minutes
    }
    
    /// Source of the wait time data
    enum WaitTimeSource: String, CaseIterable {
        case api = "API"
        case crowdSourced = "Crowd-sourced"
        case cmsAverage = "CMS Average"
        
        var displayName: String {
            return self.rawValue
        }
    }
}

/// Data point for wait time charts
struct WaitTimeDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let waitMinutes: Int
    let source: WaitTime.WaitTimeSource
}

/// Response model for the new ClockwiseMD API
struct ClockwiseMDResponse: Codable {
    let hospitalId: Int
    let hospitalWaits: HospitalWaits
    
    enum CodingKeys: String, CodingKey {
        case hospitalId = "hospital_id"
        case hospitalWaits = "hospital_waits"
    }
}

/// Hospital wait information from ClockwiseMD API
struct HospitalWaits: Codable {
    let nextAvailableVisit: Int?
    let currentWait: String?
    let queueLength: Int?
    let queueTotal: Int?
    
    enum CodingKeys: String, CodingKey {
        case nextAvailableVisit = "next_available_visit"
        case currentWait = "current_wait"
        case queueLength = "queue_length"
        case queueTotal = "queue_total"
    }
}

/// API Provider types for different urgent care systems
enum APIProvider {
    case clockwiseMD  // Total Access Urgent Care
    case mercyGoHealth  // Mercy-GoHealth Urgent Care
    case solv  // Solv platform integration
    case epic  // Epic MyChart "On My Way"
    
    var displayName: String {
        switch self {
        case .clockwiseMD: return "ClockwiseMD"
        case .mercyGoHealth: return "Mercy-GoHealth"
        case .solv: return "Solv"
        case .epic: return "Epic MyChart"
        }
    }
}

/// Response model for Mercy-GoHealth API
struct MercyGoHealthResponse: Codable {
    let locationId: String
    let waitTime: WaitTimeInfo
    let status: String
    let lastUpdated: String
    
    enum CodingKeys: String, CodingKey {
        case locationId = "location_id"
        case waitTime = "wait_time"
        case status
        case lastUpdated = "last_updated"
    }
}

/// Wait time information for Mercy-GoHealth
struct WaitTimeInfo: Codable {
    let estimatedMinutes: Int?
    let patientsWaiting: Int?
    let averageWaitTime: String?
    let nextAvailable: String?
    
    enum CodingKeys: String, CodingKey {
        case estimatedMinutes = "estimated_minutes"
        case patientsWaiting = "patients_waiting"
        case averageWaitTime = "average_wait_time"
        case nextAvailable = "next_available"
    }
}

/// Response model for Solv API
struct SolvResponse: Codable {
    let providerId: String
    let name: String
    let waitTime: SolvWaitTime?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case providerId = "provider_id"
        case name
        case waitTime = "wait_time"
        case status
    }
}

/// Solv wait time structure
struct SolvWaitTime: Codable {
    let minutes: Int?
    let status: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case minutes
        case status
        case updatedAt = "updated_at"
    }
}

/// Errors that can occur when fetching wait time data
enum WaitTimeError: Error, LocalizedError {
    case invalidURL
    case networkError
    case parsingError
    case noData
    case apiError(String)
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError:
            return "Network connection failed"
        case .parsingError:
            return "Failed to parse wait time data"
        case .noData:
            return "No wait time data available"
        case .apiError(let message):
            return "API Error: \(message)"
        case .rateLimited:
            return "Too many requests - please try again later"
        }
    }
} 