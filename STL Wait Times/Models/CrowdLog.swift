import Foundation
import CryptoKit
import UIKit

/// Represents an anonymous crowd-sourced wait time log
struct CrowdLog: Identifiable, Codable, Equatable {
    let id: String
    let facilityId: String
    let anonymousIdHash: String
    let checkInTime: Date
    let seenAtTime: Date?
    let postedAtTime: Date
    let deviceUptime: TimeInterval
    let estimatedWaitMinutes: Int?
    
    /// Computed wait time based on check-in and seen times
    var actualWaitMinutes: Int? {
        guard let seenAtTime = seenAtTime else { return nil }
        return Int(seenAtTime.timeIntervalSince(checkInTime) / 60)
    }
    
    /// Weight for crowd-sourced data based on age (linear decay over 2 hours)
    var weight: Double {
        let ageInSeconds = Date().timeIntervalSince(postedAtTime)
        let twoHoursInSeconds: TimeInterval = 2 * 60 * 60
        return max(0.0, 1.0 - (ageInSeconds / twoHoursInSeconds))
    }
    
    /// Whether this log is still valid for crowd calculations
    var isValid: Bool {
        weight > 0 && actualWaitMinutes != nil
    }
    
    init(facilityId: String, checkInTime: Date, seenAtTime: Date? = nil, estimatedWaitMinutes: Int? = nil) {
        self.id = UUID().uuidString
        self.facilityId = facilityId
        self.anonymousIdHash = CrowdLog.generateAnonymousHash()
        self.checkInTime = checkInTime
        self.seenAtTime = seenAtTime
        self.postedAtTime = Date()
        self.deviceUptime = ProcessInfo.processInfo.systemUptime
        self.estimatedWaitMinutes = estimatedWaitMinutes
    }
    
    /// Generates an anonymous hash for the device and current day
    /// This allows for deduplication without storing PII
    static func generateAnonymousHash() -> String {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        let today = dayFormatter.string(from: Date())
        
        let combinedString = "\(deviceId)-\(today)"
        let hash = SHA256.hash(data: combinedString.data(using: String.Encoding.utf8) ?? Data())
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

/// Aggregated crowd data for a facility
struct CrowdAggregation: Identifiable, Codable {
    let id: String
    let facilityId: String
    let averageWaitMinutes: Int
    let sampleCount: Int
    let lastUpdated: Date
    let confidence: Double
    
    init(facilityId: String, logs: [CrowdLog]) {
        self.id = UUID().uuidString
        self.facilityId = facilityId
        self.lastUpdated = Date()
        
        // Filter valid logs and calculate weighted average
        let validLogs = logs.filter { $0.isValid }
        guard !validLogs.isEmpty else {
            self.averageWaitMinutes = 0
            self.sampleCount = 0
            self.confidence = 0.0
            return
        }
        
        let weightedSum = validLogs.reduce(0.0) { sum, log in
            guard let waitMinutes = log.actualWaitMinutes else { return sum }
            return sum + (Double(waitMinutes) * log.weight)
        }
        
        let totalWeight = validLogs.reduce(0.0) { sum, log in
            sum + log.weight
        }
        
        self.averageWaitMinutes = totalWeight > 0 ? Int(weightedSum / totalWeight) : 0
        self.sampleCount = validLogs.count
        
        // Confidence based on sample count and recency
        let maxConfidence = min(1.0, Double(sampleCount) / 10.0) // Max confidence with 10+ samples
        let avgWeight = totalWeight / Double(sampleCount)
        self.confidence = maxConfidence * avgWeight
    }
}

/// Model for user to log their wait experience
struct WaitExperience: Identifiable {
    let id: String
    let facilityId: String
    let checkInTime: Date
    var seenAtTime: Date?
    var estimatedWaitMinutes: Int?
    
    var isComplete: Bool {
        seenAtTime != nil
    }
    
    init(facilityId: String, checkInTime: Date = Date()) {
        self.id = UUID().uuidString
        self.facilityId = facilityId
        self.checkInTime = checkInTime
    }
    
    /// Convert to CrowdLog for submission
    func toCrowdLog() -> CrowdLog {
        CrowdLog(facilityId: facilityId, checkInTime: checkInTime, seenAtTime: seenAtTime, estimatedWaitMinutes: estimatedWaitMinutes)
    }
} 