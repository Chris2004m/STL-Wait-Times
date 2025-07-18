import Foundation
import Combine
import CoreLocation

/// Service for fetching and managing wait time data from multiple Total Access APIs
class WaitTimeService: ObservableObject {
    static let shared = WaitTimeService()
    
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    @Published var waitTimes: [String: WaitTime] = [:]
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var error: WaitTimeError?
    
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
        let totalAccessFacilities = facilities.filter { $0.apiEndpoint != nil }
        guard !totalAccessFacilities.isEmpty else { 
            print("❌ No Total Access facilities found")
            return 
        }
        
        isLoading = true
        error = nil
        
        print("🚀 Starting batch fetch for \(totalAccessFacilities.count) Total Access locations...")
        
        // Process facilities in smart batches to avoid overwhelming the server
        let batchSize = 10
        let batches = totalAccessFacilities.chunked(into: batchSize)
        
        Publishers.Sequence(sequence: batches.enumerated())
            .flatMap { (batchIndex, batch) -> AnyPublisher<[WaitTime], WaitTimeError> in
                // Add delay between batches to be respectful to the API server
                let delay = batchIndex == 0 ? 0.0 : 2.0
                
                print("📦 Processing batch \(batchIndex + 1) of \(batches.count) with \(batch.count) facilities...")
                
                return Timer.publish(every: delay, on: .main, in: .common)
                    .first()
                    .flatMap { _ in
                        self.fetchBatchWaitTimes(facilities: batch)
                    }
                    .eraseToAnyPublisher()
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
            .store(in: &cancellables)
    }
    
    /// Fetches wait times for a batch of facilities in parallel
    private func fetchBatchWaitTimes(facilities: [Facility]) -> AnyPublisher<[WaitTime], WaitTimeError> {
        print("🔄 Starting batch of \(facilities.count) API calls...")
        
        let publishers = facilities.compactMap { facility -> AnyPublisher<WaitTime?, Never>? in
            print("🔍 Checking facility: \(facility.name)")
            
            guard let apiEndpoint = facility.apiEndpoint else { 
                print("⚠️ \(facility.name): No API endpoint configured")
                return nil 
            }
            
            print("✅ \(facility.name): API endpoint found - \(apiEndpoint)")
            
            // Check circuit breaker and rate limiting
            if !shouldMakeApiCall(for: apiEndpoint) {
                print("🚫 \(facility.name): Skipped due to circuit breaker or rate limiting")
                return Just(nil).eraseToAnyPublisher()
            }
            
            print("✅ \(facility.name): Passed circuit breaker and rate limiting checks")
            print("➡️ \(facility.name): Starting API call to \(apiEndpoint)")
            
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
    
    /// Fetches wait time for a single facility
    private func fetchWaitTime(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        let provider = determineAPIProvider(for: facility)
        
        print("🏥 \(facility.name): Using \(provider.displayName) API")
        
        switch provider {
        case .clockwiseMD:
            return fetchClockwiseMDWaitTime(for: facility)
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
    private func fetchClockwiseMDWaitTime(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        // Extract numeric ID from facility.id (e.g., "total-access-12604" -> "12604")
        let numericId = facility.id.components(separatedBy: "-").last ?? facility.id
        let urlString = "https://api.clockwisemd.com/v1/hospitals/\(numericId)/waits"
        
        guard let url = URL(string: urlString) else {
            print("❌ \(facility.name): Invalid URL - \(urlString)")
            return Fail(error: WaitTimeError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("🌐 \(facility.name): Fetching from \(urlString)")
        
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
                
                let waitTime = self.parseClockwiseMDWaitTime(from: response, for: facility)
                if let waitTime = waitTime {
                    print("✅ \(facility.name): Success - \(waitTime.waitMinutes) min")
                } else {
                    print("⚠️ \(facility.name): No wait time data in response")
                }
                return waitTime
            }
            .catch { error -> AnyPublisher<WaitTime?, WaitTimeError> in
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                print("⏱️ \(facility.name): Request completed in \(String(format: "%.2f", duration))s")
                
                if let urlError = error as? URLError {
                    print("❌ \(facility.name): Network error: \(urlError.localizedDescription)")
                    print("❌ Error domain: \(urlError.errorCode), code: \(urlError.code.rawValue)")
                    
                    switch urlError.code {
                    case .timedOut:
                        print("❌ TIMEOUT - Request timed out")
                    case .notConnectedToInternet:
                        print("❌ NO INTERNET - Device not connected")
                    case .cannotConnectToHost:
                        print("❌ CONNECTION FAILED - Cannot reach server")
                    default:
                        print("❌ OTHER ERROR - \(urlError.localizedDescription)")
                    }
                } else {
                    print("❌ \(facility.name): Other error: \(error.localizedDescription)")
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
            print("❌ \(facility.name): Invalid API endpoint - trying fallback approach")
            
            // If no API endpoint, try to get wait time from website scraping or alternative method
            return fetchMercyGoHealthWebsiteWaitTime(for: facility)
        }
        
        print("🌐 \(facility.name): Fetching from Solv API: \(apiEndpoint)")
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("STL-WaitLine/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("https://www.solvhealth.com", forHTTPHeaderField: "Referer") // Add referer for Solv
        request.timeoutInterval = 30.0
        
        let startTime = Date()
        return session.dataTaskPublisher(for: request)
            .timeout(.seconds(30), scheduler: DispatchQueue.global(qos: .userInitiated))
            .retry(1) // Reduce retries for external APIs
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 \(facility.name): Solv API response status: \(httpResponse.statusCode)")
                    
                    // Handle different status codes from Solv
                    switch httpResponse.statusCode {
                    case 200...299:
                        break
                    case 401:
                        throw WaitTimeError.apiError("Unauthorized - API key required")
                    case 403:
                        throw WaitTimeError.apiError("Forbidden - Access denied")
                    case 404:
                        throw WaitTimeError.apiError("Provider not found")
                    case 429:
                        throw WaitTimeError.rateLimited
                    case 500...599:
                        throw WaitTimeError.apiError("Solv server error")
                    default:
                        throw WaitTimeError.apiError("HTTP \(httpResponse.statusCode)")
                    }
                }
                
                return data
            }
            .decode(type: SolvResponse.self, decoder: JSONDecoder())
            .map { response -> WaitTime? in
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                print("⏱️ \(facility.name): Solv request completed in \(String(format: "%.2f", duration))s")
                
                let waitTime = self.parseSolvWaitTime(from: response, for: facility)
                if let waitTime = waitTime {
                    print("✅ \(facility.name): Solv success - \(waitTime.waitMinutes) min")
                } else {
                    print("⚠️ \(facility.name): No wait time data from Solv")
                }
                return waitTime
            }
            .catch { error -> AnyPublisher<WaitTime?, WaitTimeError> in
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                print("⏱️ \(facility.name): Solv request completed in \(String(format: "%.2f", duration))s")
                
                print("❌ \(facility.name): Solv error - \(error.localizedDescription)")
                
                // Fallback to website scraping approach
                return self.fetchMercyGoHealthWebsiteWaitTime(for: facility)
                    .catch { _ in Just(nil).setFailureType(to: WaitTimeError.self) }
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
                    nextAvailableSlot: 0
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
            nextAvailableSlot: waitMinutes + 10
        )
        
        print("✅ \(facility.name): Mock data - \(waitMinutes) min wait, \(patientsInLine) patients")
        
        // Simulate network delay
        return Timer.publish(every: 1.0, on: .main, in: .common)
            .first()
            .map { _ in mockWaitTime }
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
                    nextAvailableSlot: 0
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
    
    /// Parses wait time from ClockwiseMD API response
    private func parseClockwiseMDWaitTime(from response: ClockwiseMDResponse, for facility: Facility) -> WaitTime? {
        let hospitalWaits = response.hospitalWaits
        
        // Extract wait time from the response
        let waitMinutes: Int
        if let currentWait = hospitalWaits.currentWait {
            // Parse wait time from string like "4 - 19" or "15"
            if currentWait.contains(" - ") {
                let components = currentWait.components(separatedBy: " - ")
                if let minWait = Int(components[0]), let maxWait = Int(components[1]) {
                    waitMinutes = (minWait + maxWait) / 2 // Use average
                } else {
                    waitMinutes = 0
                }
            } else if let singleWait = Int(currentWait) {
                waitMinutes = singleWait
            } else {
                waitMinutes = 0
            }
        } else {
            waitMinutes = 0
        }
        
        let patientsInLine = hospitalWaits.queueLength ?? 0
        let nextAvailableSlot = hospitalWaits.nextAvailableVisit ?? 0
        
        return WaitTime(
            facilityId: facility.id,
            waitMinutes: waitMinutes,
            patientsInLine: patientsInLine,
            lastUpdated: Date(),
            nextAvailableSlot: nextAvailableSlot
        )
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
            nextAvailableSlot: nextAvailableSlot
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
            nextAvailableSlot: 0
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
                nextAvailableSlot: waitMinutes + 10
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
                nextAvailableSlot: 0
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

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - ClockwiseMD API Response Models

// Models are now defined in WaitTime.swift 