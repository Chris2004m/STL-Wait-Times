import Foundation
import Combine
import CoreLocation

/// Service for fetching and managing wait time data from multiple Total Access APIs
public class WaitTimeService: ObservableObject {
    public static let shared = WaitTimeService()
    
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    @Published var waitTimes: [String: WaitTime] = [:]
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var error: WaitTimeError?
    @Published var refreshingFacilities: Set<String> = [] // Track which facilities are being refreshed
    
    // Circuit breaker state for each API endpoint
    private var circuitBreakerState: [String: CircuitBreakerState] = [:]
    private var lastApiCall: [String: Date] = [:]
    private let minimumApiInterval: TimeInterval = 2.0 // Rate limiting: max 1 call per 2 seconds per endpoint
    
    private struct CircuitBreakerState {
        var consecutiveFailures: Int = 0
        var lastFailureTime: Date?
        var isOpen: Bool = false
        
        mutating func recordSuccess() {
            consecutiveFailures = 0
            lastFailureTime = nil
            isOpen = false
        }
        
        mutating func recordFailure() {
            consecutiveFailures += 1
            lastFailureTime = Date()
            if consecutiveFailures >= 3 {
                isOpen = true
            }
        }
        
        var shouldAttemptCall: Bool {
            if !isOpen { return true }
            guard let lastFailure = lastFailureTime else { return true }
            return Date().timeIntervalSince(lastFailure) > 300 // Retry after 5 minutes
        }
    }
    
    private init() {
        // Configure URLSession for optimal performance with multiple APIs
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0 // Longer timeout for better reliability
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        
        // Optimize for multiple concurrent requests
        config.httpMaximumConnectionsPerHost = 8
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        // Add headers for better server compatibility
        config.httpAdditionalHeaders = [
            "User-Agent": "STL-WaitLine/1.0 (iOS)",
            "Accept": "application/json",
            "Accept-Language": "en-US,en;q=0.9",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "Cache-Control": "no-cache"
        ]
        
        self.session = URLSession(configuration: config)
        
        // Test network connectivity on initialization
        testNetworkConnectivity()
    }
    
    /// Tests basic network connectivity
    private func testNetworkConnectivity() {
        print("🔍 Testing network connectivity...")
        
        guard let url = URL(string: "https://httpbin.org/get") else {
            print("❌ Failed to create test URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network connectivity test failed: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("❌ Error domain: \(nsError.domain), code: \(nsError.code)")
                    }
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("✅ Network connectivity test passed: HTTP \(httpResponse.statusCode)")
                    // If basic connectivity works, test an actual API
                    self.testTotalAccessAPI()
                } else {
                    print("⚠️ Network connectivity test: Unknown response type")
                }
            }
        }.resume()
    }
    
    /// Tests a single Total Access API endpoint
    private func testTotalAccessAPI() {
        print("🔍 Testing Total Access API...")
        
        // Test the first API endpoint with new format
        guard let url = URL(string: "https://api.clockwisemd.com/v1/hospitals/12604/waits") else {
            print("❌ Failed to create Total Access API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("STL-WaitLine/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15.0
        
        print("🌐 Making test request to: \(url)")
        
        let startTime = Date()
        session.dataTask(with: request) { data, response, error in
            let duration = Date().timeIntervalSince(startTime)
            
            DispatchQueue.main.async {
                print("⏱️ Request completed in \(String(format: "%.2f", duration))s")
                
                if let error = error {
                    print("❌ Total Access API test failed: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("❌ Error domain: \(nsError.domain), code: \(nsError.code)")
                        print("❌ Error info: \(nsError.userInfo)")
                        
                        // Specific error code analysis
                        switch nsError.code {
                        case -1001:
                            print("❌ TIMEOUT - Request timed out")
                        case -1003:
                            print("❌ HOST NOT FOUND - DNS resolution failed")
                        case -1004:
                            print("❌ CANNOT CONNECT - Server unreachable")
                        case -1009:
                            print("❌ OFFLINE - Device appears to be offline")
                        case -1022:
                            print("❌ ATS BLOCKED - App Transport Security blocked this request")
                        case -1200:
                            print("❌ SSL ERROR - Certificate or SSL issue")
                        default:
                            print("❌ UNKNOWN ERROR - Code \(nsError.code)")
                        }
                    }
                    
                    // Try a simpler HTTP request as fallback
                    self.testSimpleHTTP()
                    
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("✅ Total Access API test: HTTP \(httpResponse.statusCode)")
                    print("✅ Headers: \(httpResponse.allHeaderFields)")
                    
                    if let data = data {
                        print("✅ Received \(data.count) bytes of data")
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("📄 Response: \(jsonString.prefix(500))...")
                        }
                    }
                } else {
                    print("⚠️ Total Access API test: Unknown response type")
                }
            }
        }.resume()
    }
    
    /// Tests a simple HTTP request to isolate network issues
    private func testSimpleHTTP() {
        print("🔍 Testing simple HTTP request...")
        
        // Try a simple HTTP endpoint
        guard let url = URL(string: "http://httpbin.org/json") else {
            print("❌ Failed to create simple HTTP URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Simple HTTP test failed: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("✅ Simple HTTP test: HTTP \(httpResponse.statusCode)")
                } else {
                    print("⚠️ Simple HTTP test: Unknown response")
                }
            }
        }.resume()
    }
    
    /// Fetches wait times for all Total Access facilities in batches with smart error handling
    func fetchAllWaitTimes(facilities: [Facility]) {
        print("🔍 DEBUG: fetchAllWaitTimes called with \(facilities.count) facilities")
        for (index, facility) in facilities.enumerated() {
            print("   \(index + 1). \(facility.name) (\(facility.id))")
            print("      API: \(facility.apiEndpoint ?? "NONE")")
            
            // KIRKWOOD DEBUGGING: Check if Kirkwood is in the list
            if facility.id == "total-access-12624" {
                print("🟡 KIRKWOOD FOUND in facility list!")
                print("🟡 KIRKWOOD: Name = \(facility.name)")
                print("🟡 KIRKWOOD: API = \(facility.apiEndpoint ?? "NONE")")
            }
        }
        
        // Include ALL Total Access facilities (both API and web-scraping only)
        let totalAccessFacilities = facilities.filter { 
            $0.id.hasPrefix("total-access") || $0.apiEndpoint != nil 
        }
        print("🔍 DEBUG: Processing \(totalAccessFacilities.count) Total Access facilities (API + web scraping)")
        
        for facility in totalAccessFacilities {
            let method = facility.apiEndpoint != nil ? "API+Web" : "Web Only"
            print("   - \(facility.name): \(method)")
        }
        
        guard !totalAccessFacilities.isEmpty else { 
            print("❌ No Total Access facilities found")
            return 
        }
        
        isLoading = true
        error = nil
        
        print("🚀 Starting batch fetch for \(totalAccessFacilities.count) Total Access locations...")
        
        // Process facilities in smart batches to avoid overwhelming the server
        let batchSize = 10
        let batches = stride(from: 0, to: totalAccessFacilities.count, by: batchSize).map {
            Array(totalAccessFacilities[$0..<min($0 + batchSize, totalAccessFacilities.count)])
        }
        
        let batchPublisher = Publishers.Sequence(sequence: batches.enumerated())
            .flatMap { (batchIndex, batch) -> AnyPublisher<[WaitTime], WaitTimeError> in
                print("📦 Processing batch \(batchIndex + 1) of \(batches.count) with \(batch.count) facilities...")
                
                // For the first batch, execute immediately. For subsequent batches, add delay.
                if batchIndex == 0 {
                    print("⚡ First batch - executing immediately")
                    return self.fetchBatchWaitTimes(facilities: batch)
                } else {
                    print("⏱️ Subsequent batch - adding 2s delay")
                    return self.fetchBatchWaitTimes(facilities: batch)
                        .delay(for: .seconds(2), scheduler: DispatchQueue.main)
                        .eraseToAnyPublisher()
                }
            }
            .collect()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    switch completion {
                    case .failure(let error):
                        self?.error = error
                        print("❌ Batch fetch completed with error: \(error.localizedDescription)")
                    case .finished:
                        print("✅ All batch fetches completed successfully")
                    }
                },
                receiveValue: { [weak self] batchResults in
                    self?.lastUpdateTime = Date()
                    let allWaitTimes = batchResults.flatMap { $0 }
                    
                    // Update wait times dictionary
                    for waitTime in allWaitTimes {
                        self?.waitTimes[waitTime.facilityId] = waitTime
                    }
                    
                    print("📊 Successfully updated \(allWaitTimes.count) wait times")
                    self?.logWaitTimeStats(allWaitTimes)
                }
            )
        
        batchPublisher.store(in: &cancellables)
    }
    
    /// Fetches wait time for a single facility and updates the waitTimes dictionary
    /// Used for manual refresh of individual facilities
    func fetchSingleFacilityWaitTime(facility: Facility) {
        print("🔄 Manual refresh requested for \(facility.name)")
        
        // Prevent multiple concurrent refreshes of the same facility
        guard !refreshingFacilities.contains(facility.id) else {
            print("⚠️ Facility \(facility.name) is already being refreshed")
            return
        }
        
        // Set loading state for this specific facility
        DispatchQueue.main.async {
            self.refreshingFacilities.insert(facility.id)
        }
        
        fetchWaitTime(for: facility)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.refreshingFacilities.remove(facility.id)
                    
                    if case .failure(let error) = completion {
                        print("❌ Manual refresh failed for \(facility.name): \(error)")
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] waitTime in
                    if let waitTime = waitTime {
                        print("✅ Manual refresh successful for \(facility.name): \(waitTime.displayText)")
                        self?.waitTimes[facility.id] = waitTime
                        self?.lastUpdateTime = Date()
                    } else {
                        print("⚠️ Manual refresh returned no data for \(facility.name)")
                        // Optionally set an "N/A" wait time or keep existing data
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// Fetches wait times for a batch of facilities in parallel
    private func fetchBatchWaitTimes(facilities: [Facility]) -> AnyPublisher<[WaitTime], WaitTimeError> {
        print("🔄 Starting batch of \(facilities.count) API calls...")
        print("🔍 BATCH FACILITIES DEBUG:")
        for facility in facilities {
            print("   - \(facility.name) (\(facility.id))")
            print("     API: \(facility.apiEndpoint ?? "NONE")")
        }
        
        let publishers = facilities.compactMap { facility -> AnyPublisher<WaitTime?, Never>? in
            print("🔍 DEBUG: Checking facility: \(facility.name)")
            print("   - facility.id: \(facility.id)")
            print("   - facility.apiEndpoint: \(facility.apiEndpoint ?? "nil")")
            print("   - facility.name: \(facility.name)")
            
            // FIXED: Support facilities with web scraping only (no API endpoint)
            if let apiEndpoint = facility.apiEndpoint {
                print("✅ \(facility.name): API endpoint found - \(apiEndpoint)")
                print("🔍 \(facility.name): About to check circuit breaker and rate limiting...")
                
                // Check circuit breaker and rate limiting for API calls
                if !shouldMakeApiCall(for: apiEndpoint) {
                    print("🚫 \(facility.name): Skipped due to circuit breaker or rate limiting")
                    return Just(nil).eraseToAnyPublisher()
                }
                
                print("✅ \(facility.name): Passed circuit breaker and rate limiting checks")
                print("➡️ \(facility.name): Starting API call to \(apiEndpoint)")
            } else {
                print("🕷️ \(facility.name): No API endpoint - using WEB SCRAPING ONLY")
                print("   🌐 Website URL: \(facility.websiteURL ?? "nil")")
            }
            
            return fetchWaitTime(for: facility)
                .map { waitTime -> WaitTime? in
                    if let waitTime = waitTime {
                        print("✅ \(facility.name): Success - \(waitTime.waitMinutes) min")
                    } else {
                        print("⚠️ \(facility.name): Returned nil wait time")
                    }
                    return waitTime
                }
                .catch { error -> Just<WaitTime?> in
                    print("❌ \(facility.name): Failed - \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("❌ \(facility.name): Error domain: \(nsError.domain), code: \(nsError.code)")
                    }
                    
                    // DETAILED N/A DEBUGGING
                    if facility.name.contains("St. Peters") {
                        print("🔍 ST. PETERS N/A DEBUG:")
                        print("   - Facility ID: \(facility.id)")
                        print("   - API Endpoint: \(facility.apiEndpoint ?? "nil")")
                        print("   - Website URL: \(facility.websiteURL ?? "nil")")
                        print("   - Error: \(error)")
                        print("   - Error Type: \(type(of: error))")
                    }
                    
                    return Just(nil)
                }
                .eraseToAnyPublisher()
        }
        
        print("📊 Total facilities processed: \(facilities.count)")
        print("📊 Valid publishers created: \(publishers.count)")
        
        guard !publishers.isEmpty else {
            print("❌ No valid publishers created for batch")
            return Just([]).setFailureType(to: WaitTimeError.self).eraseToAnyPublisher()
        }
        
        print("📡 Created \(publishers.count) publishers for batch")
        
        return Publishers.MergeMany(publishers)
            .collect()
            .map { waitTimes in
                let results = waitTimes.compactMap { $0 }
                print("📊 Batch completed: \(results.count) successful out of \(waitTimes.count) attempts")
                return results
            }
            .setFailureType(to: WaitTimeError.self)
            .eraseToAnyPublisher()
    }
    
    /// Fetches wait time for a single facility - API FIRST for reliable data
    private func fetchWaitTime(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        
        // PRIORITY 1: API FIRST for reliable, structured data
        if let apiEndpoint = facility.apiEndpoint {
            print("🎯 \(facility.name): Using API as PRIMARY method for reliable data")
            print("   🔗 API Endpoint: \(apiEndpoint)")
            print("   📊 API provides structured, reliable patient count data")
            
            return fetchAPIFallback(for: facility)
                .catch { error -> AnyPublisher<WaitTime?, WaitTimeError> in
                    print("⚠️ \(facility.name): API failed, falling back to web scraping...")
                    print("   ❌ API error: \(error.localizedDescription)")
                    return self.fetchWebScrapingWaitTime(for: facility)
                }
                .eraseToAnyPublisher()
        } else {
            print("🕷️ \(facility.name): No API endpoint - using web scraping only")
            return fetchWebScrapingWaitTime(for: facility)
        }
    }
    
    /// API method - primary data source for reliable patient counts
    private func fetchAPIFallback(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        let provider = determineAPIProvider(for: facility)
        
        print("🏥 \(facility.name): Using \(provider.displayName) API as primary data source")
        
        switch provider {
        case .clockwiseMD:
            return fetchClockwiseMDAPIWaitTime(for: facility)
        case .mercyGoHealth:
            return fetchMercyGoHealthWaitTime(for: facility)
        case .solv:
            return fetchSolvWaitTime(for: facility)
        case .epic:
            return fetchEpicWaitTime(for: facility)
        case .ssmHealthFHIR:
            return fetchSSMHealthFHIRWaitTime(for: facility)
        }
    }
    
    /// Determines which API provider to use based on facility properties
    private func determineAPIProvider(for facility: Facility) -> APIProvider {
        if facility.id.hasPrefix("total-access") {
            return .clockwiseMD
        } else if facility.id.hasPrefix("mercy-gohealth") {
            return .mercyGoHealth
        } else if facility.id.hasPrefix("ssm-health") {
            return .ssmHealthFHIR
        } else if facility.apiEndpoint?.contains("solv") == true {
            return .solv
        } else if facility.apiEndpoint?.contains("epic") == true || facility.apiEndpoint?.contains("mychart") == true {
            return .epic
        } else if facility.apiEndpoint?.contains("1up.health") == true || facility.apiEndpoint?.contains("fhir") == true {
            return .ssmHealthFHIR
        } else {
            // Default to ClockwiseMD for backwards compatibility
            return .clockwiseMD
        }
    }
    
    /// Fetches wait time from ClockwiseMD API (Total Access Urgent Care)
    /// PRIORITY: Web scraping first, then API fallback for Total Access facilities
    private func fetchClockwiseMDWaitTime(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        print("🔍 DEBUG: fetchClockwiseMDWaitTime called for \(facility.name)")
        print("   - facility.id: \(facility.id)")
        print("   - facility.apiEndpoint: \(facility.apiEndpoint ?? "nil")")
        
        // For Total Access, prioritize web scraping over API for most accurate real-time data
        if facility.id.hasPrefix("total-access"), let websiteURL = facility.websiteURL {
            print("🕷️ \(facility.name): Using web scraping as PRIMARY source (more accurate than API)")
            print("   🌐 Website URL: \(websiteURL)")
            print("   🔄 This is a REFRESH call - web scraping should get latest data")
            return fetchWebScrapingWaitTime(for: facility)
                .catch { error -> AnyPublisher<WaitTime?, WaitTimeError> in
                    print("⚠️ \(facility.name): Web scraping failed, falling back to API...")
                    print("   ❌ Web scraping error: \(error.localizedDescription)")
                    return self.fetchClockwiseMDAPIWaitTime(for: facility)
                }
                .eraseToAnyPublisher()
        } else {
            print("🔗 \(facility.name): Using API as primary source (no website URL)")
            return fetchClockwiseMDAPIWaitTime(for: facility)
        }
    }
    
    /// Fetches wait time from web scraping (PRIMARY for Total Access)
    private func fetchWebScrapingWaitTime(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        guard let websiteURL = facility.websiteURL,
              let url = URL(string: websiteURL) else {
            print("❌ \(facility.name): No website URL available for scraping")
            return Fail(error: WaitTimeError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("🌐 \(facility.name): Web scraping from \(websiteURL)")
        
        var request = URLRequest(url: url)
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.timeoutInterval = 30.0
        
        let startTime = Date()
        return session.dataTaskPublisher(for: request)
            .timeout(.seconds(30), scheduler: DispatchQueue.global(qos: .userInitiated))
            .retry(1)
            .tryMap { data, response -> String in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw WaitTimeError.apiError("Invalid HTTP response")
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw WaitTimeError.apiError("HTTP \(httpResponse.statusCode)")
                }
                
                return String(data: data, encoding: .utf8) ?? ""
            }
            .tryMap { htmlContent -> WaitTime in
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                print("⏱️ \(facility.name): Web scraping completed in \(String(format: "%.2f", duration))s")
                print("📊 \(facility.name): Received \(htmlContent.count) characters of HTML content")
                
                let waitTime = self.parseWebScrapingWaitTime(htmlContent, for: facility)
                
                if let waitTime = waitTime {
                    print("✅ \(facility.name): Successfully parsed wait time from web scraping")
                    return waitTime
                } else {
                    print("❌ \(facility.name): Failed to parse wait time from web scraping - triggering API fallback")
                    throw WaitTimeError.noData
                }
            }
            .catch { error -> AnyPublisher<WaitTime?, WaitTimeError> in
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                print("⏱️ \(facility.name): Web scraping failed in \(String(format: "%.2f", duration))s")
                print("❌ \(facility.name): Web scraping error - \(error.localizedDescription)")
                return Fail(error: WaitTimeError.apiError("Web scraping failed"))
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// Parses wait time from web scraping HTML content (PRIMARY for Total Access)
    private func parseWebScrapingWaitTime(_ htmlContent: String, for facility: Facility) -> WaitTime? {
        print("🔍 \(facility.name): Parsing web scraped HTML for patients in line...")
        
        // PRIORITY 1: Check for Total Access specific JavaScript data patterns
        // Look for JavaScript variables or embedded data that contains patient counts
        let jsDataPatterns = [
            // Look for JavaScript variables that might contain patient data
            #"var\s+currentPatients\s*=\s*(\d+)"#,
            #"currentPatientsInLine\s*[:=]\s*(\d+)"#,
            #"patientsInLine\s*[:=]\s*(\d+)"#,
            #"queueLength\s*[:=]\s*(\d+)"#,
            #"waitingPatients\s*[:=]\s*(\d+)"#,
            
            // Look for data attributes or JSON that might contain patient info
            #"data-patients[^>]*?(\d+)"#,
            #"data-queue[^>]*?(\d+)"#,
            #"data-wait[^>]*?(\d+)"#,
            
            // Look for API endpoint calls that might reveal the data
            #"\/api\/[^"]*?patients[^"]*?(\d+)"#,
            #"\/api\/[^"]*?queue[^"]*?(\d+)"#,
            
            // Look for function calls that set the patient count
            #"getElementById\s*\(\s*['""]current-inline[^'"]*?['""]\s*\)\s*\.innerHTML\s*=\s*['""]?(\d+)"#,
            #"current-inline[^>]*?>\s*(\d+)\s*<"#
        ]
        
        // Add specific Total Access patterns for current-inline span elements
        let totalAccessSpecificPatterns = [
            #"current-inline-\d+["'"][^>]*?>\s*(\d+)"#,
            #"<span[^>]*id[^>]*current-inline[^>]*?>\s*(\d+)\s*</span>"#,
            #"inline-\d+["'][^>]*?[^<]*?(\d+)[^>]*?Patients\s+In\s+Line"#
        ]
        
        print("🔍 \(facility.name): Checking for JavaScript data patterns...")
        
        // First check Total Access specific patterns
        print("🎯 \(facility.name): Checking Total Access specific patterns...")
        for (index, pattern) in totalAccessSpecificPatterns.enumerated() {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: htmlContent, options: [], range: NSRange(htmlContent.startIndex..., in: htmlContent))
                
                for match in matches {
                    if let patientsRange = Range(match.range(at: 1), in: htmlContent),
                       let patientsCount = Int(htmlContent[patientsRange]) {
                        
                        let fullMatchRange = Range(match.range, in: htmlContent)!
                        let matchedText = String(htmlContent[fullMatchRange])
                        
                        if patientsCount >= 0 && patientsCount <= 50 {
                            print("✅ \(facility.name): Found \(patientsCount) patients using Total Access pattern \(index + 1)")
                            print("   📝 Matched: '\(matchedText)'")
                            print("   🎯 Pattern: \(pattern)")
                            
                            return WaitTime(
                                facilityId: facility.id,
                                waitMinutes: 0,
                                patientsInLine: patientsCount,
                                lastUpdated: Date(),
                                nextAvailableSlot: 0,
                                status: .open,
                                waitTimeRange: nil
                            )
                        }
                    }
                }
            }
        }
        for (index, pattern) in jsDataPatterns.enumerated() {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: htmlContent, options: [], range: NSRange(htmlContent.startIndex..., in: htmlContent))
                
                for match in matches {
                    if let patientsRange = Range(match.range(at: 1), in: htmlContent),
                       let patientsCount = Int(htmlContent[patientsRange]) {
                        
                        // Get context for validation
                        let fullMatchRange = Range(match.range, in: htmlContent)!
                        let _ = max(htmlContent.startIndex, htmlContent.index(fullMatchRange.lowerBound, offsetBy: -100, limitedBy: htmlContent.startIndex) ?? htmlContent.startIndex)
                        let contextEnd = min(htmlContent.endIndex, htmlContent.index(fullMatchRange.upperBound, offsetBy: 100, limitedBy: htmlContent.endIndex) ?? htmlContent.endIndex)
                        let matchedText = String(htmlContent[fullMatchRange])
                        
                        // Validate the number is reasonable (0-50 patients for urgent care)
                        if patientsCount >= 0 && patientsCount <= 50 {
                            print("✅ \(facility.name): Found \(patientsCount) patients using JS pattern \(index + 1)")
                            print("   📝 Matched: '\(matchedText)'")
                            print("   🎯 Pattern: \(pattern)")
                            
                            return WaitTime(
                                facilityId: facility.id,
                                waitMinutes: 0, // Wait time not reliably available from website
                                patientsInLine: patientsCount,
                                lastUpdated: Date(),
                                nextAvailableSlot: 0,
                                status: .open,
                                waitTimeRange: nil
                            )
                        } else {
                            print("⚠️ \(facility.name): Rejected unreasonable JS patient count: \(patientsCount)")
                        }
                    }
                }
            }
        }
        
        // PRIORITY 2: Look for any numbers near "Patients In Line" text
        // This handles cases where the number might be loaded but not in the expected format
        print("🔍 \(facility.name): Searching for numbers near 'Patients In Line' text...")
        if let patientsInLineRange = htmlContent.range(of: "Patients In Line", options: .caseInsensitive) {
            // Look for numbers within 200 characters before or after "Patients In Line"
            let searchStart = max(htmlContent.startIndex, htmlContent.index(patientsInLineRange.lowerBound, offsetBy: -200, limitedBy: htmlContent.startIndex) ?? htmlContent.startIndex)
            let searchEnd = min(htmlContent.endIndex, htmlContent.index(patientsInLineRange.upperBound, offsetBy: 200, limitedBy: htmlContent.endIndex) ?? htmlContent.endIndex)
            let searchArea = String(htmlContent[searchStart..<searchEnd])
            
            let numberPattern = #"\b(\d+)\b"#
            if let regex = try? NSRegularExpression(pattern: numberPattern, options: []) {
                let matches = regex.matches(in: searchArea, options: [], range: NSRange(searchArea.startIndex..., in: searchArea))
                
                for match in matches {
                    if let numberRange = Range(match.range(at: 1), in: searchArea),
                       let patientCount = Int(searchArea[numberRange]) {
                        
                        // Only accept reasonable patient counts
                        if patientCount >= 0 && patientCount <= 50 {
                            // Get more context to validate this is actually the patient count
                            let matchStart = max(searchArea.startIndex, searchArea.index(numberRange.lowerBound, offsetBy: -50, limitedBy: searchArea.startIndex) ?? searchArea.startIndex)
                            let matchEnd = min(searchArea.endIndex, searchArea.index(numberRange.upperBound, offsetBy: 50, limitedBy: searchArea.endIndex) ?? searchArea.endIndex)
                            let context = String(searchArea[matchStart..<matchEnd]).lowercased()
                            
                            // Exclude numbers that are clearly not patient counts
                            let excludeContext = ["year", "month", "day", "hour", "phone", "address", "zip", "menu", "nav", "link", "2025", "2024"]
                            let isExcluded = excludeContext.contains { excludePattern in
                                context.contains(excludePattern)
                            }
                            
                            if !isExcluded {
                                print("✅ \(facility.name): Found \(patientCount) patients near 'Patients In Line' text")
                                print("   📝 Context: '\(context)'")
                                
                                return WaitTime(
                                    facilityId: facility.id,
                                    waitMinutes: 0,
                                    patientsInLine: patientCount,
                                    lastUpdated: Date(),
                                    nextAvailableSlot: 0,
                                    status: .open,
                                    waitTimeRange: nil
                                )
                            }
                        }
                    }
                }
            }
        }
        
        // PRIORITY 3: Standard patterns for other urgent care websites
        // Patterns ordered by specificity (most specific first)
        let patientsPatterns = [
            // Most specific ClockwiseMD patterns (PRIORITY)
            #"Currently\s+(\d+)\s+in\s+line"#,
            #"currently\s+(\d+)\s+in\s+line"#,
            
            // Exact Total Access patterns (most specific)
            #"(?:patients?\s+in\s+line|in\s+line)\s*:?\s*(\d+)"#,
            #"(\d+)\s+patients?\s+(?:currently\s+)?in\s+line"#,
            #"(\d+)\s+patients?\s+(?:currently\s+)?waiting"#,
            #"(?:currently|now)\s+(\d+)\s+patients?\s+(?:in\s+line|waiting)"#,
            
            // Queue status patterns  
            #"queue\s*:?\s*(\d+)\s+patients?"#,
            #"(\d+)\s+(?:people|patients?)\s+(?:ahead|in\s+front)"#,
            #"waiting\s+(?:room|queue)\s*:?\s*(\d+)"#,
            
            // Check-in counter patterns
            #"checked[\s-]*in\s*:?\s*(\d+)"#,
            #"(\d+)\s+checked[\s-]*in"#,
            
            // Status display patterns (avoid navigation links)
            #"(?:status|current)\s*:?\s*(\d+)\s+(?:patients?|people)\s+(?:waiting|in\s+line)"#
        ]
        
        // Try each pattern with detailed logging and context validation
        for (index, pattern) in patientsPatterns.enumerated() {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: htmlContent, options: [], range: NSRange(htmlContent.startIndex..., in: htmlContent))
                
                for match in matches {
                    if let patientsRange = Range(match.range(at: 1), in: htmlContent),
                       let patientsCount = Int(htmlContent[patientsRange]) {
                        
                        // Get surrounding context for validation (larger context)
                        let fullMatchRange = Range(match.range, in: htmlContent)!
                        let contextStart = max(htmlContent.startIndex, htmlContent.index(fullMatchRange.lowerBound, offsetBy: -100, limitedBy: htmlContent.startIndex) ?? htmlContent.startIndex)
                        let contextEnd = min(htmlContent.endIndex, htmlContent.index(fullMatchRange.upperBound, offsetBy: 100, limitedBy: htmlContent.endIndex) ?? htmlContent.endIndex)
                        let contextText = String(htmlContent[contextStart..<contextEnd]).lowercased()
                        let matchedText = String(htmlContent[fullMatchRange])
                        
                        // ENHANCED VALIDATION: Exclude navigation, header, and link content
                        let excludePatterns = [
                            "nav", "menu", "header", "footer", "link", "href", "totalaccessurgentcare.com",
                            "elementor", "class=", "id=", "src=", "alt=", "title=", "aria-",
                            "javascript", "onclick", "style=", "<a ", "</a>", "<img", "<div",
                            "patient portal", "plan-your-visit", "tabindex", "contact", "about"
                        ]
                        
                        let isExcluded = excludePatterns.contains { excludePattern in
                            contextText.contains(excludePattern)
                        }
                        
                        if isExcluded {
                            print("⚠️ \(facility.name): Rejected match from navigation/header: '\(matchedText)'")
                            print("   📝 Context: ...\(contextText.prefix(200))...")
                            continue
                        }
                        
                        // Validate the number is reasonable (0-50 patients for urgent care)
                        if patientsCount >= 0 && patientsCount <= 50 {
                            print("✅ \(facility.name): Found \(patientsCount) patients using pattern \(index + 1)")
                            print("   📝 Matched text: '\(matchedText)'")
                            print("   🎯 Pattern: \(pattern)")
                            print("   ✅ Context validation passed")
                            
                            return WaitTime(
                                facilityId: facility.id,
                                waitMinutes: 0, // Wait time not reliably available from website
                                patientsInLine: patientsCount,
                                lastUpdated: Date(),
                                nextAvailableSlot: 0,
                                status: .open,
                                waitTimeRange: nil
                            )
                        } else {
                            print("⚠️ \(facility.name): Rejected unreasonable patient count: \(patientsCount) from '\(matchedText)'")
                        }
                    }
                }
            }
        }
        
        // If no specific patient patterns found, look for zero/no-wait indicators
        let noWaitPatterns = [
            #"no\s+wait"#,
            #"no\s+waiting"#,
            #"walk\s+right\s+in"#,
            #"available\s+now"#,
            #"0\s+patients?\s+in\s+line"#,
            #"0\s+patients?\s+waiting"#,
            #"no\s+one\s+waiting"#,
            #"empty\s+waiting\s+room"#
        ]
        
        for (index, pattern) in noWaitPatterns.enumerated() {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: htmlContent, options: [], range: NSRange(htmlContent.startIndex..., in: htmlContent)) {
                
                let matchRange = Range(match.range, in: htmlContent)!
                let matchedText = String(htmlContent[matchRange])
                
                print("✅ \(facility.name): Found no-wait indicator using pattern \(index + 1): '\(matchedText)'")
                
                return WaitTime(
                    facilityId: facility.id,
                    waitMinutes: 0,
                    patientsInLine: 0,
                    lastUpdated: Date(),
                    nextAvailableSlot: 0,
                    status: .open,
                    waitTimeRange: nil
                )
            }
        }
        
        // Check for SPECIFIC closed indicators (avoid false positives like "keep doors closed")
        let closedPatterns = [
            // Very specific facility closure patterns
            #"(?:facility|location|clinic|urgent\s+care)\s+(?:is\s+)?(?:currently\s+)?closed"#,
            #"(?:temporarily|permanently)\s+closed"#,
            #"closed\s+(?:for|until|today|now)"#,
            #"we\s+are\s+(?:currently\s+)?closed"#,
            #"location\s+(?:is\s+)?not\s+available"#,
            #"service\s+(?:is\s+)?unavailable"#,
            #"no\s+longer\s+accepting\s+patients"#,
            #"hours:\s*closed"#, // For "Hours: Closed" type displays
            #"status:\s*closed"#  // For "Status: Closed" type displays
        ]
        
        for (index, pattern) in closedPatterns.enumerated() {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: htmlContent, options: [], range: NSRange(htmlContent.startIndex..., in: htmlContent)) {
                
                let matchRange = Range(match.range, in: htmlContent)!
                let matchedText = String(htmlContent[matchRange])
                
                // Additional validation - check surrounding context for false positives
                let contextStart = max(htmlContent.startIndex, htmlContent.index(matchRange.lowerBound, offsetBy: -100, limitedBy: htmlContent.startIndex) ?? htmlContent.startIndex)
                let contextEnd = min(htmlContent.endIndex, htmlContent.index(matchRange.upperBound, offsetBy: 100, limitedBy: htmlContent.endIndex) ?? htmlContent.endIndex)
                let contextText = String(htmlContent[contextStart..<contextEnd]).lowercased()
                
                // Exclude matches that are clearly not about facility status
                let falsePositiveIndicators = [
                    "keep", "door", "gate", "window", "please", "remember", "always", "ensure", "policy", "safety"
                ]
                
                let isFalsePositive = falsePositiveIndicators.contains { indicator in
                    contextText.contains(indicator)
                }
                
                if isFalsePositive {
                    print("⚠️ \(facility.name): Rejected false positive closed indicator: '\(matchedText)'")
                    print("   📝 Context: ...\(contextText.prefix(200))...")
                    continue
                }
                
                print("🔒 \(facility.name): Found legitimate closed indicator using pattern \(index + 1): '\(matchedText)'")
                print("   📝 Context: ...\(contextText.prefix(200))...")
                
                return WaitTime(
                    facilityId: facility.id,
                    waitMinutes: 0,
                    patientsInLine: 0,
                    lastUpdated: Date(),
                    nextAvailableSlot: 0,
                    status: .closed,
                    waitTimeRange: nil
                )
            }
        }
        
        print("❌ \(facility.name): No patients in line data found in web content")
        print("📊 \(facility.name): HTML content length: \(htmlContent.count) characters")
        
        // ENHANCED DEBUG: Look for any numbers that might indicate patient counts
        let numberPattern = #"\b\d+\b"#
        if let regex = try? NSRegularExpression(pattern: numberPattern, options: []) {
            let matches = regex.matches(in: htmlContent, options: [], range: NSRange(htmlContent.startIndex..., in: htmlContent))
            print("🔢 \(facility.name): Found \(matches.count) numbers in content")
            
            // Show first 10 numbers with context
            for (index, match) in matches.prefix(10).enumerated() {
                if let numberRange = Range(match.range, in: htmlContent) {
                    let number = String(htmlContent[numberRange])
                    let contextStart = max(htmlContent.startIndex, htmlContent.index(numberRange.lowerBound, offsetBy: -30, limitedBy: htmlContent.startIndex) ?? htmlContent.startIndex)
                    let contextEnd = min(htmlContent.endIndex, htmlContent.index(numberRange.upperBound, offsetBy: 30, limitedBy: htmlContent.endIndex) ?? htmlContent.endIndex)
                    let context = String(htmlContent[contextStart..<contextEnd])
                    print("   \(index + 1). '\(number)' in context: ...\(context)...")
                }
            }
        }
        
        // For debugging, log HTML snippets that might contain patient data
        let debugSnippets = [
            "patient", "waiting", "line", "queue", "count", "check", "current", "in line", "wait time"
        ]
        
        print("🔍 \(facility.name): Searching for key terms in HTML...")
        for snippet in debugSnippets {
            if let range = htmlContent.range(of: snippet, options: .caseInsensitive) {
                let start = max(htmlContent.startIndex, htmlContent.index(range.lowerBound, offsetBy: -80, limitedBy: htmlContent.startIndex) ?? htmlContent.startIndex)
                let end = min(htmlContent.endIndex, htmlContent.index(range.upperBound, offsetBy: 80, limitedBy: htmlContent.endIndex) ?? htmlContent.endIndex)
                let context = String(htmlContent[start..<end])
                print("📝 \(facility.name): Found '\(snippet)' context: ...\(context)...")
            } else {
                print("❌ \(facility.name): Did NOT find '\(snippet)' in content")
            }
        }
        
        // Save first 2000 characters for debugging
        let debugContent = String(htmlContent.prefix(2000))
        print("📄 \(facility.name): HTML Preview (first 2000 chars):\n\(debugContent)")
        
        // Return nil to indicate no data found (will trigger API fallback)
        return nil
    }
    
    /// Fetches wait time from ClockwiseMD API (FALLBACK for Total Access)
    private func fetchClockwiseMDAPIWaitTime(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        // Extract numeric ID from facility.id (e.g., "total-access-12604" -> "12604")
        // Use apiEndpoint directly from facility data (contains correct ClockwiseMD API URL)
        guard let apiEndpoint = facility.apiEndpoint else {
            print("❌ \(facility.name): Missing ClockwiseMD API endpoint")
            return Fail(error: WaitTimeError.invalidURL)
                .eraseToAnyPublisher()
        }
        guard let url = URL(string: apiEndpoint) else {
            print("❌ \(facility.name): Invalid ClockwiseMD API URL - \(apiEndpoint)")
            return Fail(error: WaitTimeError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("🎯 \(facility.name): Using direct ClockwiseMD API endpoint: \(apiEndpoint)")
        print("🌐 \(facility.name): Fetching from \(apiEndpoint)")
        print("🚀 \(facility.name): Starting ClockwiseMD API request...")
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("STL-WaitLine/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30.0
        
        let startTime = Date()
        return session.dataTaskPublisher(for: request)
            .timeout(.seconds(30), scheduler: DispatchQueue.global(qos: .userInitiated))
            .retry(2) // Retry twice for transient failures
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    guard 200...299 ~= httpResponse.statusCode else {
                        print("❌ \(facility.name): HTTP error \(httpResponse.statusCode)")
                        throw WaitTimeError.apiError("HTTP \(httpResponse.statusCode)")
                    }
                }
                return data
            }
            .decode(type: ClockwiseMDResponse.self, decoder: JSONDecoder())
            .map { response -> WaitTime? in
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                print("⏱️ \(facility.name): Request completed in \(String(format: "%.2f", duration))s")
                
                // DETAILED ST. PETERS API RESPONSE DEBUGGING
                if facility.name.contains("St. Peters") {
                    print("🔍 ST. PETERS API RESPONSE DEBUG:")
                    print("   - Raw Response: \(response)")
                    print("   - appointment_queues count: \(response.appointmentQueues?.count ?? 0)")
                    if let queues = response.appointmentQueues {
                        for (index, queue) in queues.enumerated() {
                            print("   - Queue \(index): queueId=\(queue.queueId ?? -1), patients=\(queue.queueWaits?.currentPatientsInLine ?? -1)")
                        }
                    }
                }
                
                let isKirkwood = facility.id == "total-access-12624"
                if isKirkwood {
                    print("🟡 KIRKWOOD SUCCESS: API request completed successfully!")
                    print("🟡 KIRKWOOD: About to parse response...")
                }
                
                let waitTime = self.parseClockwiseMDWaitTime(from: response, for: facility)
                
                if let waitTime = waitTime {
                    print("✅ \(facility.name): Success - \(waitTime.waitMinutes) min")
                    if isKirkwood {
                        print("🟡 KIRKWOOD: Parsing completed successfully!")
                        print("🟡 KIRKWOOD: WaitTime object created")
                    }
                } else {
                    print("⚠️ \(facility.name): No wait time data in response")
                    if isKirkwood {
                        print("🟡 KIRKWOOD: Parsing returned nil - this means parsing failed!")
                    }
                }
                return waitTime
            }
            .catch { error -> AnyPublisher<WaitTime?, WaitTimeError> in
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                print("⏱️ \(facility.name): Request completed in \(String(format: "%.2f", duration))s")
                
                // KIRKWOOD DEBUGGING: Special error tracking
                let isKirkwood = facility.id == "total-access-12624"
                if isKirkwood {
                    print("🟡 KIRKWOOD ERROR: API request failed!")
                    print("🟡 KIRKWOOD: Duration: \(String(format: "%.2f", duration))s")
                    print("🟡 KIRKWOOD: Error type: \(type(of: error))")
                }
                
                if let urlError = error as? URLError {
                    print("❌ \(facility.name): Network error: \(urlError.localizedDescription)")
                    print("❌ Error domain: \(urlError.errorCode), code: \(urlError.code.rawValue)")
                    
                    if isKirkwood {
                        print("🟡 KIRKWOOD: URLError code: \(urlError.code.rawValue)")
                        print("🟡 KIRKWOOD: URLError description: \(urlError.localizedDescription)")
                    }
                    
                    switch urlError.code {
                    case .timedOut:
                        print("❌ TIMEOUT - Request timed out")
                        if isKirkwood { print("🟡 KIRKWOOD: Request timed out after 30s") }
                    case .notConnectedToInternet:
                        print("❌ NO INTERNET - Device not connected")
                        if isKirkwood { print("🟡 KIRKWOOD: No internet connection") }
                    case .cannotConnectToHost:
                        print("❌ CONNECTION FAILED - Cannot reach server")
                        if isKirkwood { print("🟡 KIRKWOOD: Cannot connect to ClockwiseMD server") }
                    default:
                        print("❌ OTHER ERROR - \(urlError.localizedDescription)")
                        if isKirkwood { print("🟡 KIRKWOOD: Other URL error: \(urlError.localizedDescription)") }
                    }
                } else {
                    print("❌ \(facility.name): Other error: \(error.localizedDescription)")
                    if isKirkwood {
                        print("🟡 KIRKWOOD: Non-URL error: \(error.localizedDescription)")
                    }
                }
                
                return Just(nil)
                    .setFailureType(to: WaitTimeError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// Fetches wait time from Mercy-GoHealth via Solv API
    private func fetchMercyGoHealthWaitTime(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        guard let apiEndpoint = facility.apiEndpoint,
              let url = URL(string: apiEndpoint) else {
            print("❌ \(facility.name): No Mercy API endpoint configured")
            return Just(nil)
                .setFailureType(to: WaitTimeError.self)
                .eraseToAnyPublisher()
        }
        
        print("🏥 \(facility.name): Fetching from Mercy API: \(apiEndpoint)")
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("STL-WaitLine/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("https://www.mercy.net", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 30.0
        
        let startTime = Date()
        return session.dataTaskPublisher(for: request)
            .timeout(.seconds(30), scheduler: DispatchQueue.global(qos: .userInitiated))
            .retry(1)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 \(facility.name): Mercy API response status: \(httpResponse.statusCode)")
                    
                    guard httpResponse.statusCode == 200 else {
                        throw WaitTimeError.apiError("HTTP \(httpResponse.statusCode)")
                    }
                }
                return data
            }
            .decode(type: MercyResponse.self, decoder: JSONDecoder())
            .map { response -> WaitTime? in
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                print("⏱️ \(facility.name): Mercy request completed in \(String(format: "%.2f", duration))s")
                
                // DETAILED MERCY DEBUGGING
                print("🔍 MERCY DEBUG for \(facility.name):")
                print("   - Raw API Response: \(response)")
                print("   - Wait Time: \(response.time) minutes")
                print("   - Facility ID: \(facility.id)")
                
                let waitTime = WaitTime(
                    facilityId: facility.id,
                    waitMinutes: response.time,
                    patientsInLine: 0, // Mercy API doesn't provide patient count
                    lastUpdated: Date(),
                    nextAvailableSlot: 0, // Not provided by Mercy API
                    status: .open,
                    waitTimeRange: nil
                )
                
                print("✅ \(facility.name): Created Mercy WaitTime object - \(response.time) minutes")
                print("✅ \(facility.name): WaitTime.waitMinutes = \(waitTime.waitMinutes)")
                print("✅ \(facility.name): WaitTime.status = \(waitTime.status)")
                
                return waitTime
            }
            .catch { error -> AnyPublisher<WaitTime?, WaitTimeError> in
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                print("⏱️ \(facility.name): Mercy request completed in \(String(format: "%.2f", duration))s")
                print("❌ \(facility.name): Mercy API error - \(error.localizedDescription)")
                
                return Just(nil)
                    .setFailureType(to: WaitTimeError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// Fallback method to get wait times from Mercy-GoHealth website
    private func fetchMercyGoHealthWebsiteWaitTime(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        guard let websiteURL = facility.websiteURL,
              let url = URL(string: websiteURL) else {
            print("❌ \(facility.name): No website URL available")
            return Just(nil)
                .setFailureType(to: WaitTimeError.self)
                .eraseToAnyPublisher()
        }
        
        print("🌐 \(facility.name): Trying website fallback: \(websiteURL)")
        
        var request = URLRequest(url: url)
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("STL-WaitLine/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30.0
        
        return session.dataTaskPublisher(for: request)
            .timeout(.seconds(30), scheduler: DispatchQueue.global(qos: .userInitiated))
            .tryMap { data, response -> String in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw WaitTimeError.apiError("Website request failed")
                }
                
                return String(data: data, encoding: .utf8) ?? ""
            }
            .map { htmlContent -> WaitTime? in
                // Parse HTML content for wait time information
                return self.parseHTMLWaitTime(htmlContent, for: facility)
            }
            .catch { error -> AnyPublisher<WaitTime?, WaitTimeError> in
                print("❌ \(facility.name): Website fallback failed - \(error.localizedDescription)")
                return Just(nil)
                    .setFailureType(to: WaitTimeError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// Parse HTML content for wait time information
    private func parseHTMLWaitTime(_ htmlContent: String, for facility: Facility) -> WaitTime? {
        // Look for common wait time patterns in HTML
        let waitTimePatterns = [
            #"wait[^>]*?(\d+)[^>]*?min"#,
            #"(\d+)[^>]*?minute[s]?\s+wait"#,
            #"current[^>]*?wait[^>]*?(\d+)"#,
            #"wait[^>]*?time[^>]*?(\d+)"#
        ]
        
        for pattern in waitTimePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: htmlContent, options: [], range: NSRange(htmlContent.startIndex..., in: htmlContent)),
               let waitTimeRange = Range(match.range(at: 1), in: htmlContent),
               let waitMinutes = Int(htmlContent[waitTimeRange]) {
                
                print("✅ \(facility.name): Parsed wait time from website - \(waitMinutes) min")
                
                return WaitTime(
                    facilityId: facility.id,
                    waitMinutes: waitMinutes,
                    patientsInLine: 0, // Not available from website
                    lastUpdated: Date(),
                    nextAvailableSlot: 0,
                    status: .open,
                    waitTimeRange: nil
                )
            }
        }
        
        print("⚠️ \(facility.name): No wait time found in website content")
        return nil
    }
    
    /// Fetches wait time from Solv API
    private func fetchSolvWaitTime(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        // TODO: Implement Solv API integration
        print("⚠️ \(facility.name): Solv API not yet implemented")
        return Just(nil)
            .setFailureType(to: WaitTimeError.self)
            .eraseToAnyPublisher()
    }
    
    /// Fetches wait time from Epic MyChart API
    private func fetchEpicWaitTime(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        // TODO: Implement Epic MyChart API integration
        print("⚠️ \(facility.name): Epic MyChart API not yet implemented")
        return Just(nil)
            .setFailureType(to: WaitTimeError.self)
            .eraseToAnyPublisher()
    }
    
    /// Fetches wait time from SSM Health via 1upHealth FHIR API
    private func fetchSSMHealthFHIRWaitTime(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        guard let apiEndpoint = facility.apiEndpoint else {
            print("❌ \(facility.name): No FHIR API endpoint configured")
            
            // Return mock data for development/testing
            return fetchSSMHealthMockWaitTime(for: facility)
        }
        
        print("🌐 \(facility.name): Fetching from SSM Health FHIR API: \(apiEndpoint)")
        
        // For now, return mock data until we have actual API credentials
        // This allows the app to work while pursuing business partnership
        return fetchSSMHealthMockWaitTime(for: facility)
        
        /* TODO: Implement actual FHIR API call when credentials are available
        
        // Step 1: Authenticate with OAuth 2.0
        return authenticateSSMHealthFHIR()
            .flatMap { token in
                // Step 2: Query FHIR Observation resources for wait times
                return self.querySSMHealthWaitTimes(facility: facility, token: token)
            }
            .eraseToAnyPublisher()
        */
    }
    
    /// Returns mock wait time data for SSM Health facilities during development
    private func fetchSSMHealthMockWaitTime(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        print("🎭 \(facility.name): Returning mock SSM Health wait time data")
        
        // Generate realistic mock data based on facility type and time of day
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        // Simulate different wait times based on time of day
        let baseWaitTime: Int
        switch hour {
        case 6...10:  // Morning rush
            baseWaitTime = facility.facilityType == .emergencyDepartment ? 45 : 25
        case 11...14: // Lunch time
            baseWaitTime = facility.facilityType == .emergencyDepartment ? 35 : 20
        case 15...18: // Afternoon busy
            baseWaitTime = facility.facilityType == .emergencyDepartment ? 60 : 35
        case 19...22: // Evening peak
            baseWaitTime = facility.facilityType == .emergencyDepartment ? 75 : 40
        default:      // Overnight
            baseWaitTime = facility.facilityType == .emergencyDepartment ? 20 : 15
        }
        
        // Add some randomness (+/- 15 minutes)
        let randomOffset = Int.random(in: -15...15)
        let waitMinutes = max(0, baseWaitTime + randomOffset)
        
        // Estimate patients in line based on wait time
        let patientsInLine = waitMinutes > 0 ? max(1, waitMinutes / 8) : 0
        
        let mockWaitTime = WaitTime(
            facilityId: facility.id,
            waitMinutes: waitMinutes,
            patientsInLine: patientsInLine,
            lastUpdated: Date(),
            nextAvailableSlot: waitMinutes + 10,
            status: .open,
            waitTimeRange: nil
        )
        
        print("✅ \(facility.name): Mock data - \(waitMinutes) min wait, \(patientsInLine) patients")
        
        // Simulate network delay without creating persistent timers
        return Just(mockWaitTime)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .setFailureType(to: WaitTimeError.self)
            .eraseToAnyPublisher()
    }
    
    /// Authenticates with SSM Health FHIR API via OAuth 2.0
    private func authenticateSSMHealthFHIR() -> AnyPublisher<FHIROAuthToken, WaitTimeError> {
        // TODO: Implement OAuth 2.0 authentication when credentials are available
        print("🔐 Authenticating with SSM Health FHIR API...")
        
        let mockToken = FHIROAuthToken(
            accessToken: "mock_access_token",
            tokenType: "Bearer",
            expiresIn: 3600,
            scope: "patient/Observation.read"
        )
        
        return Just(mockToken)
            .setFailureType(to: WaitTimeError.self)
            .eraseToAnyPublisher()
    }
    
    /// Queries SSM Health FHIR API for wait time observations
    private func querySSMHealthWaitTimes(facility: Facility, token: FHIROAuthToken) -> AnyPublisher<WaitTime?, WaitTimeError> {
        // TODO: Implement actual FHIR query when API access is available
        print("📊 Querying SSM Health FHIR for wait time observations...")
        
        // Mock FHIR query would look like:
        // GET /fhir/dstu2/Observation?category=survey&code=wait-time&subject.identifier=facility-id
        
        return fetchSSMHealthMockWaitTime(for: facility)
    }
    
    /// Parses wait time from SSM Health FHIR Observation resources
    private func parseSSMHealthFHIRWaitTime(from bundle: FHIRBundle, for facility: Facility) -> WaitTime? {
        guard let entries = bundle.entry, !entries.isEmpty else {
            print("⚠️ \(facility.name): No FHIR observations found")
            return nil
        }
        
        // Look for wait time observations
        for entry in entries {
            let observation = entry.resource
            
            // Check if this is a wait time observation
            if let code = observation.code,
               let coding = code.coding?.first,
               coding.code == "wait-time" || coding.display?.lowercased().contains("wait") == true {
                
                // Extract wait time value
                let waitMinutes: Int
                if let quantity = observation.valueQuantity, let value = quantity.value {
                    waitMinutes = Int(value)
                } else if let valueString = observation.valueString,
                          let extractedMinutes = extractMinutesFromString(valueString) {
                    waitMinutes = extractedMinutes
                } else {
                    continue
                }
                
                print("✅ \(facility.name): Parsed FHIR wait time - \(waitMinutes) min")
                
                return WaitTime(
                    facilityId: facility.id,
                    waitMinutes: waitMinutes,
                    patientsInLine: 0, // Not typically available in FHIR
                    lastUpdated: Date(),
                    nextAvailableSlot: 0,
                    status: .open,
                    waitTimeRange: nil
                )
            }
        }
        
        print("⚠️ \(facility.name): No wait time observations found in FHIR bundle")
        return nil
    }
    
    /// Extracts minutes from various string formats
    private func extractMinutesFromString(_ timeString: String) -> Int? {
        let patterns = [
            #"(\d+)\s*min"#,
            #"(\d+)\s*minute"#,
            #"wait[^\d]*(\d+)"#,
            #"(\d+)[^\d]*wait"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: timeString, options: [], range: NSRange(timeString.startIndex..., in: timeString)),
               let minutesRange = Range(match.range(at: 1), in: timeString),
               let minutes = Int(timeString[minutesRange]) {
                return minutes
            }
        }
        
        return nil
    }
    
    /// Parses wait time from ClockwiseMD API response - Prioritizing patients in line data
    private func parseClockwiseMDWaitTime(from response: ClockwiseMDResponse, for facility: Facility) -> WaitTime? {
        let hospitalWaits = response.hospitalWaits
        let currentTime = Date()
        
        // KIRKWOOD DEBUGGING: Special debugging for facility 12624
        let isKirkwood = facility.id == "total-access-12624"
        let debugPrefix = isKirkwood ? "🟡 KIRKWOOD DEBUG" : "🏥"
        
        print("\(debugPrefix) \(facility.name): Processing ClockwiseMD response at \(currentTime)")
        print("   📊 Raw API Data:")
        print("      - Facility ID: \(facility.id)")
        print("      - Hospital ID from API: \(response.hospitalId)")
        print("      - currentWait: \(hospitalWaits.currentWait ?? "nil")")
        print("      - queueLength: \(hospitalWaits.queueLength ?? 0)")
        print("      - queueTotal: \(hospitalWaits.queueTotal ?? 0) (CAPACITY - NOT CURRENT PATIENTS)")
        print("      - nextAvailableVisit: \(hospitalWaits.nextAvailableVisit ?? 0)")
        
        if isKirkwood {
            print("🟡 KIRKWOOD: This is the facility showing N/A - tracking every step...")
        }
        
        // COMPREHENSIVE DEBUGGING: Check if appointment queues exist
        print("   🔭 DEBUGGING: Checking appointment queues...")
        if let appointmentQueues = response.appointmentQueues {
            print("   ✅ appointmentQueues exists! Count: \(appointmentQueues.count)")
        } else {
            print("   ❌ appointmentQueues is NIL!")
        }
        
        // PRIORITY 1: Extract ACTUAL patients in line data from appointment queues (most accurate)
        var patientsInLine = 0
        var debugSource = "UNKNOWN"
        var individualQueueCounts: [Int] = []
        var waitTimeRange: String? = nil
        
        // First, try to get patients in line from individual appointment queues (most accurate)
        if let appointmentQueues = response.appointmentQueues {
            print("   📋 Appointment Queues Data (\(appointmentQueues.count) queues):")
            debugSource = "appointment_queues"
            
            for (index, queue) in appointmentQueues.enumerated() {
                print("      Queue \(index + 1):")
                print("         - queueId: \(queue.queueId ?? -1)")
                
                if let queueWaits = queue.queueWaits {
                    let queuePatients = queueWaits.currentPatientsInLine ?? 0
                    print("         - currentPatientsInLine: \(queuePatients)")
                    print("         - currentWait: \(queueWaits.currentWait ?? -1)")
                    print("         - currentWaitRange: \(queueWaits.currentWaitRange ?? "nil")")
                    patientsInLine += queuePatients
                    individualQueueCounts.append(queuePatients)
                    
                    // Capture wait time range from first queue with valid data (ignore N/A ranges)
                    if waitTimeRange == nil, let range = queueWaits.currentWaitRange, range != "N/A" && !range.isEmpty {
                        waitTimeRange = range
                        print("         → Captured waitTimeRange: '\(range)'")
                    }
                } else {
                    print("         - queueWaits: NIL")
                    individualQueueCounts.append(0)
                }
            }
            print("   👥 TOTAL Patients in line (from appointment queues): \(patientsInLine)")
            print("   🔢 Individual queue counts: \(individualQueueCounts)")
            print("   ⏱️ Wait time range: \(waitTimeRange ?? "nil")")
            
            // CRITICAL VALIDATION: Ensure we're not accidentally using queue_total
            if patientsInLine == hospitalWaits.queueTotal {
                print("   ⚠️ WARNING: Patient count matches queueTotal (\(hospitalWaits.queueTotal ?? 0)) - possible parsing error!")
                print("   ⚠️ queueTotal represents CAPACITY, not current patients!")
                print("   ⚠️ Using correct appointment queue sum: \(patientsInLine)")
            }
        } else {
            // Fallback to top-level queue data - but NEVER use queueTotal
            patientsInLine = hospitalWaits.queueLength ?? 0
            debugSource = "hospital_waits.queue_length"
            print("   👥 Patients in line (from hospital_waits.queue_length): \(patientsInLine)")
            print("   ⚠️ NOT using queueTotal (\(hospitalWaits.queueTotal ?? 0)) - that's capacity!")
        }
        
        let queueTotal = hospitalWaits.queueTotal ?? 0
        let nextAvailableSlot = hospitalWaits.nextAvailableVisit ?? 0
        
        print("   🔍 FINAL DECISION:")
        print("      - Source: \(debugSource)")
        print("      - patientsInLine: \(patientsInLine) ← THIS IS WHAT USERS SEE")
        print("      - queueTotal: \(queueTotal) (CAPACITY - NOT DISPLAYED)")
        print("      - queueLength: \(hospitalWaits.queueLength ?? 0) (fallback only)")
        
        // VALIDATION: Compare with website expectation
        self.validatePatientCount(facility: facility, calculatedCount: patientsInLine, queueTotal: queueTotal)
        
        // PRIORITY 2: Determine facility status
        let status: WaitTime.FacilityStatus
        let waitMinutes: Int // Still extract for backup/comparison
        
        if let currentWait = hospitalWaits.currentWait {
            let currentWaitLowercased = currentWait.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for closed/unavailable status first
            if currentWaitLowercased.contains("closed") || currentWaitLowercased == "closed" {
                print("🔒 \(facility.name): Facility is CLOSED - currentWait: '\(currentWait)'")
                status = .closed
                waitMinutes = 0
            } else if currentWaitLowercased.contains("n/a") || currentWaitLowercased == "n/a" || 
                      currentWaitLowercased.contains("unavailable") || currentWaitLowercased == "unavailable" {
                print("⚠️ \(facility.name): currentWait shows N/A, but checking if we have queue data...")
                
                if isKirkwood {
                    print("🟡 KIRKWOOD DEBUG: N/A condition triggered!")
                    print("🟡 KIRKWOOD: currentWait = '\(currentWait)'")
                    print("🟡 KIRKWOOD: currentWaitLowercased = '\(currentWaitLowercased)'")
                    print("🟡 KIRKWOOD: patientsInLine = \(patientsInLine)")
                    print("🟡 KIRKWOOD: queueTotal = \(queueTotal)")
                    print("🟡 KIRKWOOD: Condition (patientsInLine >= 0): \(patientsInLine >= 0)")
                    print("🟡 KIRKWOOD: Condition (queueTotal > 0): \(queueTotal > 0)")
                    print("🟡 KIRKWOOD: Combined condition: \(patientsInLine >= 0 || queueTotal > 0)")
                }
                
                // SPECIAL HANDLING: If currentWait is N/A but we have queue data, prioritize queue data
                if patientsInLine >= 0 || queueTotal > 0 {
                    print("✅ \(facility.name): Queue data available despite N/A currentWait - treating as OPEN")
                    if isKirkwood {
                        print("🟡 KIRKWOOD: Setting status to .open - should display 'No patients'")
                    }
                    status = .open
                    waitMinutes = 0
                } else {
                    print("❌ \(facility.name): Service UNAVAILABLE - currentWait: '\(currentWait)' and no queue data")
                    if isKirkwood {
                        print("🟡 KIRKWOOD: Setting status to .unavailable - would display 'N/A'")
                    }
                    status = .unavailable
                    waitMinutes = 0
                }
            } else {
                // Facility is open - parse wait time for reference
                if currentWait.contains(" - ") {
                    let components = currentWait.components(separatedBy: " - ")
                    if let minWait = Int(components[0]), let maxWait = Int(components[1]) {
                        waitMinutes = (minWait + maxWait) / 2
                        status = .open
                    } else {
                        waitMinutes = 0
                        status = .open // Still open, just couldn't parse wait time
                    }
                } else if let singleWait = Int(currentWait) {
                    waitMinutes = singleWait
                    status = .open
                } else {
                    waitMinutes = 0
                    status = .open // Assume open if we can't parse wait time
                }
            }
        } else {
            // No currentWait field - check if we have queue data to determine status
            if patientsInLine >= 0 || queueTotal > 0 {
                status = .open // If we have queue data, assume facility is open
                waitMinutes = 0
                print("ℹ️ \(facility.name): No currentWait but have queue data - assuming OPEN")
            } else {
                status = .unknown
                waitMinutes = 0
                print("❓ \(facility.name): No wait time or queue data available")
            }
        }
        
        // Log the final extracted data (patients in line is the priority)
        print("✅ \(facility.name): Extracted data:")
        print("   👥 Patients in line: \(patientsInLine)")
        print("   📊 Queue capacity: \(queueTotal)")
        print("   ⏱️ Wait time (backup): \(waitMinutes) min")
        print("   🏥 Status: \(status)")
        
        // KIRKWOOD FIX: Don't use web scraping fallback when API provides valid data
        // Only use web scraping if API truly has no queue data (no appointment_queues)
        if status == .open && patientsInLine == 0 && queueTotal == 0 && response.appointmentQueues == nil {
            print("🔍 \(facility.name): No queue data from API, attempting web scraping fallback...")
            // Web scraping will be handled asynchronously - return current data for now
            // The web scraping will update the waitTimes dictionary when it completes
            DispatchQueue.global(qos: .background).async {
                self.scrapeWebsitePatientsInLine(for: facility)
            }
        } else if patientsInLine == 0 && response.appointmentQueues != nil {
            if isKirkwood {
                print("🟡 KIRKWOOD: API provided valid appointment queues with 0 patients - NOT using web scraping")
                print("🟡 KIRKWOOD: This should prevent the incorrect '3 patients' override")
            }
        }
        
        let waitTime = WaitTime(
            facilityId: facility.id,
            waitMinutes: waitMinutes, // Backup data
            patientsInLine: patientsInLine, // Primary data we want to display
            lastUpdated: currentTime,
            nextAvailableSlot: nextAvailableSlot,
            status: status,
            waitTimeRange: waitTimeRange
        )
        
        if isKirkwood {
            print("🟡 KIRKWOOD FINAL: Created WaitTime object:")
            print("🟡 KIRKWOOD: - facilityId: \(waitTime.facilityId)")
            print("🟡 KIRKWOOD: - status: \(waitTime.status)")
            print("🟡 KIRKWOOD: - patientsInLine: \(waitTime.patientsInLine)")
            print("🟡 KIRKWOOD: - waitMinutes: \(waitTime.waitMinutes)")
            print("🟡 KIRKWOOD: - patientDisplayText: '\(waitTime.patientDisplayText)'")
            print("🟡 KIRKWOOD: - displayText: '\(waitTime.displayText)'")
            print("🟡 KIRKWOOD: If this shows 'N/A', the issue is in the UI layer, not parsing!")
        }
        
        return waitTime
    }
    
    /// Validates patient count against expected values and logs discrepancies
    private func validatePatientCount(facility: Facility, calculatedCount: Int, queueTotal: Int) {
        let facilityName = facility.name
        let facilityId = facility.id
        
        // For facility 13598 (and others), we know the website often shows different values
        // Log detailed validation information
        print("🔍 VALIDATION for \(facilityName) (\(facilityId)):")
        print("   📱 App calculated count: \(calculatedCount)")
        print("   🌐 Expected from website: Should match current API appointment_queues sum")
        print("   ⚠️ Queue total (capacity): \(queueTotal) - DO NOT USE for patient count")
        
        // Check for common discrepancy patterns
        if calculatedCount == queueTotal && queueTotal > 0 {
            print("   🚨 CRITICAL: App might be showing capacity (\(queueTotal)) instead of actual patients (\(calculatedCount))")
            print("   🚨 This is the exact issue the user reported!")
        }
        
        // Store validation data for potential debugging
        let validationData: [String: Any] = [
            "facility_id": facilityId,
            "facility_name": facilityName,
            "calculated_count": calculatedCount,
            "queue_total": queueTotal,
            "timestamp": Date().iso8601String
        ]
        
        // Log for debugging purposes
        print("   📊 Validation data: \(validationData)")
        
        // If there's a potential discrepancy, log it prominently
        if calculatedCount != 0 && calculatedCount == queueTotal {
            print("⚠️⚠️⚠️ POTENTIAL PATIENT COUNT DISCREPANCY DETECTED ⚠️⚠️⚠️")
            print("Facility: \(facilityName)")
            print("Calculated patients: \(calculatedCount)")
            print("Queue capacity: \(queueTotal)")
            print("If these match, we might be using capacity instead of actual patient count!")
            print("⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️")
        }
    }
    
    /// MARK: - Web Scraping for Total Access Urgent Care
    
    /// Scrapes patients in line data from Total Access website as fallback
    private func scrapeWebsitePatientsInLine(for facility: Facility) {
        guard let websiteURL = facility.websiteURL,
              let url = URL(string: websiteURL) else {
            print("❌ \(facility.name): No website URL available for scraping")
            return
        }
        
        print("🕷️ \(facility.name): Starting web scraping from \(websiteURL)")
        
        var request = URLRequest(url: url)
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.timeoutInterval = 30.0
        
        let startTime = Date()
        session.dataTask(with: request) { [weak self] data, response, error in
            let duration = Date().timeIntervalSince(startTime)
            
            if let error = error {
                print("❌ \(facility.name): Web scraping failed after \(String(format: "%.2f", duration))s - \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ \(facility.name): Invalid HTTP response")
                return
            }
            
            print("📊 \(facility.name): Web scraping HTTP \(httpResponse.statusCode) in \(String(format: "%.2f", duration))s")
            
            guard httpResponse.statusCode == 200,
                  let data = data,
                  let htmlContent = String(data: data, encoding: .utf8) else {
                print("❌ \(facility.name): Failed to get HTML content")
                return
            }
            
            print("📝 \(facility.name): Received \(data.count) bytes of HTML content")
            
            // Parse the HTML for patients in line data
            if let patientsInLine = self?.parseHTMLPatientsInLine(htmlContent, for: facility) {
                print("✅ \(facility.name): Successfully scraped \(patientsInLine) patients in line")
                
                // Update the wait time with scraped data
                DispatchQueue.main.async {
                    self?.updateWaitTimeWithScrapedData(facility: facility, patientsInLine: patientsInLine)
                }
            } else {
                print("⚠️ \(facility.name): Could not extract patients in line from website")
            }
        }.resume()
    }
    
    /// Parses HTML content to extract patients in line information
    private func parseHTMLPatientsInLine(_ htmlContent: String, for facility: Facility) -> Int? {
        print("🔍 \(facility.name): Parsing HTML for patients in line data...")
        
        // Common patterns for patients in line on Total Access websites
        let patientsPatterns = [
            // Direct patterns for "X patients in line"
            #"(\d+)\s+patients?\s+in\s+line"#,
            #"(\d+)\s+patients?\s+waiting"#,
            #"(\d+)\s+patients?\s+ahead"#,
            
            // Queue length patterns
            #"queue[^\d]*(\d+)"#,
            #"line[^\d]*(\d+)"#,
            #"waiting[^\d]*(\d+)"#,
            
            // Wait room patterns
            #"(\d+)\s+people\s+waiting"#,
            #"(\d+)\s+people\s+in\s+line"#,
            #"(\d+)\s+people\s+ahead"#,
            
            // Current status patterns
            #"currently\s+(\d+)\s+patients?"#,
            #"now\s+serving\s+(\d+)"#,
            #"(\d+)\s+currently\s+waiting"#,
            
            // Check-in patterns
            #"checked\s+in[^\d]*(\d+)"#,
            #"(\d+)\s+checked\s+in"#
        ]
        
        // Try each pattern
        for (index, pattern) in patientsPatterns.enumerated() {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: htmlContent, options: [], range: NSRange(htmlContent.startIndex..., in: htmlContent))
                
                for match in matches {
                    if let patientsRange = Range(match.range(at: 1), in: htmlContent),
                       let patientsCount = Int(htmlContent[patientsRange]) {
                        
                        // Validate the number is reasonable (0-50 patients)
                        if patientsCount >= 0 && patientsCount <= 50 {
                            print("✅ \(facility.name): Found \(patientsCount) patients using pattern \(index + 1): \(pattern)")
                            return patientsCount
                        } else {
                            print("⚠️ \(facility.name): Rejected unreasonable patient count: \(patientsCount)")
                        }
                    }
                }
            }
        }
        
        // If no specific patient patterns found, look for general wait indicators
        let waitIndicators = [
            "no wait", "no waiting", "walk right in", "available now"
        ]
        
        let htmlLower = htmlContent.lowercased()
        for indicator in waitIndicators {
            if htmlLower.contains(indicator) {
                print("✅ \(facility.name): Found no-wait indicator: '\(indicator)'")
                return 0
            }
        }
        
        // Check for closed indicators
        let closedIndicators = [
            "closed", "temporarily closed", "not available", "unavailable"
        ]
        
        for indicator in closedIndicators {
            if htmlLower.contains(indicator) {
                print("🔒 \(facility.name): Found closed indicator: '\(indicator)'")
                return nil // Return nil to indicate facility is closed
            }
        }
        
        print("❌ \(facility.name): No patients in line data found in HTML content")
        
        // For debugging, save a sample of the HTML
        let sampleHTML = String(htmlContent.prefix(1000))
        print("📝 \(facility.name): HTML Sample: \(sampleHTML)")
        
        return nil
    }
    
    /// Updates the cached wait time with scraped patients in line data
    private func updateWaitTimeWithScrapedData(facility: Facility, patientsInLine: Int) {
        print("🔄 \(facility.name): Updating wait time with scraped data - \(patientsInLine) patients")
        
        // Get existing wait time or create a new one
        let existingWaitTime = waitTimes[facility.id]
        
        let updatedWaitTime = WaitTime(
            facilityId: facility.id,
            waitMinutes: existingWaitTime?.waitMinutes ?? 0, // Keep existing wait time as backup
            patientsInLine: patientsInLine, // Use scraped data
            lastUpdated: Date(),
            nextAvailableSlot: existingWaitTime?.nextAvailableSlot ?? 0,
            status: patientsInLine >= 0 ? .open : .closed,
            waitTimeRange: existingWaitTime?.waitTimeRange // Preserve existing wait time range
        )
        
        // Update the published wait times
        waitTimes[facility.id] = updatedWaitTime
        
        print("✅ \(facility.name): Wait time updated with scraped data - \(patientsInLine) patients in line")
    }
    
    /// Parses wait time from Mercy-GoHealth API response (deprecated - using Solv now)
    private func parseMercyGoHealthWaitTime(from response: MercyGoHealthResponse, for facility: Facility) -> WaitTime? {
        let waitTimeInfo = response.waitTime
        
        // Extract wait time from the response
        let waitMinutes = waitTimeInfo.estimatedMinutes ?? 0
        let patientsInLine = waitTimeInfo.patientsWaiting ?? 0
        
        // Parse next available if provided
        let nextAvailableSlot: Int
        if let nextAvailable = waitTimeInfo.nextAvailable,
           let minutes = extractMinutesFromTimeString(nextAvailable) {
            nextAvailableSlot = minutes
        } else {
            nextAvailableSlot = 0
        }
        
        return WaitTime(
            facilityId: facility.id,
            waitMinutes: waitMinutes,
            patientsInLine: patientsInLine,
            lastUpdated: Date(),
            nextAvailableSlot: nextAvailableSlot,
            status: .open,
            waitTimeRange: nil
        )
    }
    
    /// Parses wait time from Solv API response
    private func parseSolvWaitTime(from response: SolvResponse, for facility: Facility) -> WaitTime? {
        // Extract wait time from Solv response
        let waitMinutes: Int
        let patientsInLine: Int
        
        if let solvWaitTime = response.waitTime {
            waitMinutes = solvWaitTime.minutes ?? 0
            // Solv doesn't provide patient count, estimate based on wait time
            patientsInLine = waitMinutes > 0 ? max(1, waitMinutes / 15) : 0
        } else {
            // No wait time data available
            waitMinutes = 0
            patientsInLine = 0
        }
        
        return WaitTime(
            facilityId: facility.id,
            waitMinutes: waitMinutes,
            patientsInLine: patientsInLine,
            lastUpdated: Date(),
            nextAvailableSlot: 0,
            status: .open,
            waitTimeRange: nil
        )
    }
    
    /// Helper method to extract minutes from time strings like "15 min" or "1 hour 30 min"
    private func extractMinutesFromTimeString(_ timeString: String) -> Int? {
        let components = timeString.lowercased().components(separatedBy: " ")
        var totalMinutes = 0
        
        for i in 0..<components.count {
            if components[i].contains("hour") && i > 0,
               let hours = Int(components[i-1]) {
                totalMinutes += hours * 60
            } else if components[i].contains("min") && i > 0,
                      let minutes = Int(components[i-1]) {
                totalMinutes += minutes
            }
        }
        
        return totalMinutes > 0 ? totalMinutes : nil
    }
    
    /// Checks if we should make an API call based on circuit breaker and rate limiting
    private func shouldMakeApiCall(for apiEndpoint: String) -> Bool {
        // Check circuit breaker
        let breakerState = circuitBreakerState[apiEndpoint, default: CircuitBreakerState()]
        if !breakerState.shouldAttemptCall {
            print("🚫 Circuit breaker open for \(apiEndpoint)")
            return false
        }
        
        // Check rate limiting
        if let lastCall = lastApiCall[apiEndpoint] {
            let timeSinceLastCall = Date().timeIntervalSince(lastCall)
            if timeSinceLastCall < minimumApiInterval {
                print("🚫 Rate limited for \(apiEndpoint) - \(timeSinceLastCall)s since last call")
                return false
            }
        }
        
        return true
    }
    
    /// Gets the best available wait time for a facility
    func getBestWaitTime(for facility: Facility) -> WaitTime? {
        // First try to get from cache
        if let cachedWaitTime = waitTimes[facility.id], !cachedWaitTime.isStale {
            return cachedWaitTime
        }
        
        // For SSM Health facilities, generate mock data if no cached data
        if facility.id.hasPrefix("ssm-health") {
            // Generate mock wait time for immediate display
            let hour = Calendar.current.component(.hour, from: Date())
            let baseWait = facility.facilityType == .emergencyDepartment ? 45 : 25
            let timeMultiplier = hour >= 15 && hour <= 20 ? 1.5 : 1.0 // Busier in evening
            let waitMinutes = Int(Double(baseWait) * timeMultiplier) + Int.random(in: -10...10)
            
            return WaitTime(
                facilityId: facility.id,
                waitMinutes: max(0, waitMinutes),
                patientsInLine: max(0, waitMinutes / 8),
                lastUpdated: Date(),
                nextAvailableSlot: waitMinutes + 10,
                status: .open,
                waitTimeRange: nil
            )
        }
        
        // If no cached data or stale, return CMS average for EDs
        if facility.facilityType == .emergencyDepartment,
           let cmsAverage = facility.cmsAverageWaitMinutes {
            return WaitTime(
                facilityId: facility.id,
                waitMinutes: cmsAverage,
                patientsInLine: 0,
                lastUpdated: Date(),
                nextAvailableSlot: 0,
                status: .open,
                waitTimeRange: nil
            )
        }
        
        // Return nil if no data available
        return nil
    }
    
    /// Logs wait time statistics for monitoring
    private func logWaitTimeStats(_ waitTimes: [WaitTime]) {
        guard !waitTimes.isEmpty else {
            print("📈 No wait times to analyze")
            return
        }
        
        let sortedByWait = waitTimes.sorted { $0.waitMinutes < $1.waitMinutes }
        
        let minWait = sortedByWait.first?.waitMinutes ?? 0
        let maxWait = sortedByWait.last?.waitMinutes ?? 0
        let avgWait = waitTimes.map { $0.waitMinutes }.reduce(0, +) / waitTimes.count
        
        let noWaitCount = waitTimes.filter { $0.waitMinutes == 0 }.count
        let longWaitCount = waitTimes.filter { $0.waitMinutes > 30 }.count
        
        print("📈 Wait Time Stats:")
        print("   Range: \(minWait)-\(maxWait) min | Avg: \(avgWait) min")
        print("   No wait: \(noWaitCount) | Long wait (>30min): \(longWaitCount)")
    }
}

// MARK: - Helper Extensions

extension Date {
    /// Returns ISO8601 formatted string for consistent timestamps
    internal var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}



// MARK: - ClockwiseMD API Response Models

// Models are now defined in WaitTime.swift 