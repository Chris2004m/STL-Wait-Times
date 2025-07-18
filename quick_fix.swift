// Quick fix: Add this method to replace the current fetchWaitTime method

    /// Fetches wait time for a single facility - API FIRST for testing
    private func fetchWaitTime(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        
        // TEMPORARY: Use API FIRST to test if it works
        if let apiEndpoint = facility.apiEndpoint {
            print("🔗 \\(facility.name): Using API as PRIMARY method for testing")
            print("   🌐 API URL: \\(apiEndpoint)")
            
            return fetchAPIFallback(for: facility)
                .flatMap { waitTime -> AnyPublisher<WaitTime?, WaitTimeError> in
                    if let waitTime = waitTime {
                        print("✅ \\(facility.name): API succeeded, using API data")
                        return Just(waitTime).setFailureType(to: WaitTimeError.self).eraseToAnyPublisher()
                    } else {
                        print("⚠️ \\(facility.name): API returned nil, trying web scraping...")
                        if let websiteURL = facility.websiteURL {
                            return self.fetchWebScrapingWaitTime(for: facility)
                        } else {
                            return Just(nil).setFailureType(to: WaitTimeError.self).eraseToAnyPublisher()
                        }
                    }
                }
                .catch { error -> AnyPublisher<WaitTime?, WaitTimeError> in
                    print("⚠️ \\(facility.name): API failed, trying web scraping...")
                    print("   ❌ API error: \\(error.localizedDescription)")
                    if let websiteURL = facility.websiteURL {
                        return self.fetchWebScrapingWaitTime(for: facility)
                    } else {
                        return Just(nil).setFailureType(to: WaitTimeError.self).eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
        } else {
            print("🔗 \\(facility.name): No API endpoint - using web scraping only")
            if let websiteURL = facility.websiteURL {
                return fetchWebScrapingWaitTime(for: facility)
            } else {
                return Just(nil).setFailureType(to: WaitTimeError.self).eraseToAnyPublisher()
            }
        }
    }