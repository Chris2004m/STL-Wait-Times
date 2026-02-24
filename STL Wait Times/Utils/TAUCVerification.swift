import Foundation
import Combine

/// Utility class to verify TAUC patient counts match website data
class TAUCVerification {
    private let waitTimeService = WaitTimeService.shared
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    /// Verification result for a single facility
    struct VerificationResult {
        let facilityId: String
        let facilityName: String
        let apiPatientCount: Int?
        let websitePatientCount: Int?
        let matches: Bool
        let error: String?
    }
    
    /// Verify patient counts for a specific facility
    /// - Parameters:
    ///   - facility: The facility to verify
    ///   - completion: Completion handler with verification result
    func verifyFacility(_ facility: Facility, completion: @escaping (VerificationResult) -> Void) {
        guard facility.id.hasPrefix("total-access") else {
            completion(VerificationResult(
                facilityId: facility.id,
                facilityName: facility.name,
                apiPatientCount: nil,
                websitePatientCount: nil,
                matches: false,
                error: "Not a TAUC facility"
            ))
            return
        }
        
        let group = DispatchGroup()
        var apiPatientCount: Int?
        var websitePatientCount: Int?
        var errorMessage: String?
        
        // Get patient count from API
        group.enter()
        if let waitTime = waitTimeService.getBestWaitTime(for: facility) {
            apiPatientCount = waitTime.patientsInLine
            group.leave()
        } else {
            // Force fetch from API if no cached data
            waitTimeService.fetchAllWaitTimes(facilities: [facility])
            
            // Wait a bit for the API call to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if let waitTime = self.waitTimeService.getBestWaitTime(for: facility) {
                    apiPatientCount = waitTime.patientsInLine
                }
                group.leave()
            }
        }
        
        // Get patient count from website
        group.enter()
        if let websiteURL = facility.websiteURL, let url = URL(string: websiteURL) {
            fetchWebsitePatientCount(url: url) { count in
                websitePatientCount = count
                group.leave()
            }
        } else {
            errorMessage = "No website URL available"
            group.leave()
        }
        
        // Combine results
        group.notify(queue: .main) {
            let matches = apiPatientCount == websitePatientCount
            completion(VerificationResult(
                facilityId: facility.id,
                facilityName: facility.name,
                apiPatientCount: apiPatientCount,
                websitePatientCount: websitePatientCount,
                matches: matches,
                error: errorMessage
            ))
        }
    }
    
    /// Fetch patient count from website HTML
    private func fetchWebsitePatientCount(url: URL, completion: @escaping (Int?) -> Void) {
        session.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8),
                  error == nil else {
                debugLog("❌ Error fetching website data: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            // Extract patient count from HTML
            let patientCount = self.parsePatientCount(from: htmlString)
            completion(patientCount)
        }.resume()
    }
    
    /// Parse patient count from HTML content
    private func parsePatientCount(from html: String) -> Int? {
        // Look for patterns like "3 Patients In Line" or "0 Patients In Line"
        let patterns = [
            #"(\d+)\s+Patients?\s+In\s+Line"#,
            #"(\d+)\s+patients?\s+in\s+line"#,
            #"(\d+)\s+PATIENTS?\s+IN\s+LINE"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let patientCountRange = Range(match.range(at: 1), in: html),
               let patientCount = Int(html[patientCountRange]) {
                return patientCount
            }
        }
        
        return nil
    }
    
    /// Verify multiple facilities
    /// - Parameters:
    ///   - facilities: Array of facilities to verify
    ///   - completion: Completion handler with all verification results
    func verifyMultipleFacilities(_ facilities: [Facility], completion: @escaping ([VerificationResult]) -> Void) {
        let group = DispatchGroup()
        var results: [VerificationResult] = []
        
        for facility in facilities {
            group.enter()
            verifyFacility(facility) { result in
                results.append(result)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(results)
        }
    }
    
    /// Print verification results in a formatted way
    static func printResults(_ results: [VerificationResult]) {
        debugLog("\n📊 TAUC Patient Count Verification Results")
        debugLog("=" * 50)
        
        var matchCount = 0
        var totalCount = 0
        
        for result in results {
            totalCount += 1
            if result.matches { matchCount += 1 }
            
            let status = result.matches ? "✅ MATCH" : "❌ MISMATCH"
            let apiCount = result.apiPatientCount?.description ?? "N/A"
            let webCount = result.websitePatientCount?.description ?? "N/A"
            
            debugLog("\n\(status) - \(result.facilityName)")
            debugLog("  API: \(apiCount) patients")
            debugLog("  Website: \(webCount) patients")
            
            if let error = result.error {
                debugLog("  Error: \(error)")
            }
        }
        
        debugLog("\n" + "=" * 50)
        debugLog("📈 Summary: \(matchCount)/\(totalCount) facilities match")
        let percentage = totalCount > 0 ? (Double(matchCount) / Double(totalCount)) * 100 : 0
        debugLog("📊 Accuracy: \(String(format: "%.1f", percentage))%")
    }
}

// Extension to support string multiplication
extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}