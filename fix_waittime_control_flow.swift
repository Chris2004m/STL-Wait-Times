// Fixed control flow for web scraping + API fallback

    /// Fetches wait time for a single facility - WEB SCRAPING FIRST for all facilities
    private func fetchWaitTime(for facility: Facility) -> AnyPublisher<WaitTime?, WaitTimeError> {
        
        // PRIORITY 1: WEB SCRAPING for ALL facilities (most accurate real-time data)
        if let websiteURL = facility.websiteURL {
            print("🕷️ \\(facility.name): Using WEB SCRAPING as PRIMARY method for all facilities")
            print("   🌐 Website URL: \\(websiteURL)")
            print("   🔄 Web scraping provides most accurate real-time data")
            
            return fetchWebScrapingWaitTime(for: facility)
                .flatMap { waitTime -> AnyPublisher<WaitTime?, WaitTimeError> in
                    if let waitTime = waitTime {
                        print("✅ \\(facility.name): Web scraping succeeded, using scraped data")
                        return Just(waitTime).setFailureType(to: WaitTimeError.self).eraseToAnyPublisher()
                    } else {
                        print("⚠️ \\(facility.name): Web scraping returned nil, falling back to API...")
                        return self.fetchAPIFallback(for: facility)
                    }
                }
                .catch { error -> AnyPublisher<WaitTime?, WaitTimeError> in
                    print("⚠️ \\(facility.name): Web scraping failed with error, falling back to API...")
                    print("   ❌ Web scraping error: \\(error.localizedDescription)")
                    return self.fetchAPIFallback(for: facility)
                }
                .eraseToAnyPublisher()
        } else {
            print("🔗 \\(facility.name): No website URL - using API only")
            return fetchAPIFallback(for: facility)
        }
    }