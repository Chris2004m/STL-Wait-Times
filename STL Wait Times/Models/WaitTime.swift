import Foundation

/// Represents wait time data for a healthcare facility
struct WaitTime: Identifiable {
    let id = UUID()
    let facilityId: String
    let waitMinutes: Int
    let patientsInLine: Int
    let lastUpdated: Date
    let nextAvailableSlot: Int
    let status: FacilityStatus
    
    /// Status of the facility
    enum FacilityStatus {
        case open
        case closed
        case unavailable
        case unknown
    }
    
    var displayText: String {
        switch status {
        case .closed:
            return "N/A"
        case .unavailable:
            return "N/A"
        case .unknown:
            return "N/A"
        case .open:
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
    }
    
    /// Display text for patient count (used for TAUC facilities)
    var patientDisplayText: String {
        switch status {
        case .closed:
            return "N/A"
        case .unavailable:
            return "N/A"
        case .unknown:
            return "N/A"
        case .open:
            if patientsInLine == 0 {
                return "No patients"
            } else if patientsInLine == 1 {
                return "1 patient"
            } else {
                return "\(patientsInLine) patients"
            }
        }
    }
    
    /// Whether this facility is currently available for new patients
    var isAvailable: Bool {
        return status == .open
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
    let appointmentQueues: [AppointmentQueue]?
    
    enum CodingKeys: String, CodingKey {
        case hospitalId = "hospital_id"
        case hospitalWaits = "hospital_waits"
        case appointmentQueues = "appointment_queues"
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
    
    // Custom decoder to handle nextAvailableVisit as either Int or String
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle nextAvailableVisit which can be Int or String ("N/A")
        if let intValue = try? container.decode(Int.self, forKey: .nextAvailableVisit) {
            nextAvailableVisit = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .nextAvailableVisit) {
            // If it's a string like "N/A", treat as nil
            nextAvailableVisit = Int(stringValue) // Will be nil for "N/A"
        } else {
            nextAvailableVisit = nil
        }
        
        // Standard decoding for other fields
        currentWait = try container.decodeIfPresent(String.self, forKey: .currentWait)
        queueLength = try container.decodeIfPresent(Int.self, forKey: .queueLength)
        queueTotal = try container.decodeIfPresent(Int.self, forKey: .queueTotal)
    }
}

/// Individual appointment queue from ClockwiseMD API
struct AppointmentQueue: Codable {
    let queueId: Int?
    let queueWaits: QueueWaits?
    
    enum CodingKeys: String, CodingKey {
        case queueId = "queue_id"
        case queueWaits = "queue_waits"
    }
}

/// Wait information for a specific queue
struct QueueWaits: Codable {
    let currentWait: Int?
    let currentPatientsInLine: Int?
    let currentWaitRange: String?
    
    enum CodingKeys: String, CodingKey {
        case currentWait = "current_wait"
        case currentPatientsInLine = "current_patients_in_line"
        case currentWaitRange = "current_wait_range"
    }
}

/// API Provider types for different urgent care systems
enum APIProvider {
    case clockwiseMD  // Total Access Urgent Care
    case mercyGoHealth  // Mercy-GoHealth Urgent Care
    case solv  // Solv platform integration
    case epic  // Epic MyChart "On My Way"
    case ssmHealthFHIR  // SSM Health via 1upHealth FHIR API
    
    var displayName: String {
        switch self {
        case .clockwiseMD: return "ClockwiseMD"
        case .mercyGoHealth: return "Mercy-GoHealth"
        case .solv: return "Solv"
        case .epic: return "Epic MyChart"
        case .ssmHealthFHIR: return "SSM Health FHIR"
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

/// FHIR Response models for SSM Health via 1upHealth
struct FHIRBundle: Codable {
    let resourceType: String
    let id: String?
    let type: String
    let total: Int?
    let entry: [FHIRBundleEntry]?
}

struct FHIRBundleEntry: Codable {
    let resource: FHIRObservation
}

struct FHIRObservation: Codable {
    let resourceType: String
    let id: String?
    let status: String?
    let category: [FHIRCodeableConcept]?
    let code: FHIRCodeableConcept?
    let subject: FHIRReference?
    let valueQuantity: FHIRQuantity?
    let valueString: String?
    let effectiveDateTime: String?
    
    enum CodingKeys: String, CodingKey {
        case resourceType, id, status, category, code, subject
        case valueQuantity, valueString
        case effectiveDateTime = "effectiveDateTime"
    }
}

struct FHIRCodeableConcept: Codable {
    let coding: [FHIRCoding]?
    let text: String?
}

struct FHIRCoding: Codable {
    let system: String?
    let code: String?
    let display: String?
}

struct FHIRReference: Codable {
    let reference: String?
    let display: String?
}

struct FHIRQuantity: Codable {
    let value: Double?
    let unit: String?
    let system: String?
    let code: String?
}

/// SSM Health specific response model
struct SSMHealthResponse: Codable {
    let facilityId: String
    let waitTime: SSMWaitTimeInfo
    let status: String
    let lastUpdated: String
    let dataSource: String
    
    enum CodingKeys: String, CodingKey {
        case facilityId = "facility_id"
        case waitTime = "wait_time"
        case status
        case lastUpdated = "last_updated"
        case dataSource = "data_source"
    }
}

struct SSMWaitTimeInfo: Codable {
    let currentWaitMinutes: Int?
    let estimatedWaitMinutes: Int?
    let patientsInQueue: Int?
    let nextAvailableSlot: String?
    let urgentCareStatus: String?
    let emergencyDeptStatus: String?
    
    enum CodingKeys: String, CodingKey {
        case currentWaitMinutes = "current_wait_minutes"
        case estimatedWaitMinutes = "estimated_wait_minutes"
        case patientsInQueue = "patients_in_queue"
        case nextAvailableSlot = "next_available_slot"
        case urgentCareStatus = "urgent_care_status"
        case emergencyDeptStatus = "emergency_dept_status"
    }
}

/// Authentication model for FHIR APIs
struct FHIROAuthToken: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let scope: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case scope
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
    case authenticationFailed
    case fhirError(String)
    
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
        case .authenticationFailed:
            return "Authentication failed - API credentials required"
        case .fhirError(let message):
            return "FHIR API Error: \(message)"
        }
    }
} 