# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Running
- **Build**: Use Xcode to build the project (`⌘+B`)
- **Run on Simulator**: Select iPhone simulator (iOS 17+) and run (`⌘+R`)
- **Run Tests**: `⌘+U` for unit tests and UI tests

### Testing
- **Unit Tests**: Located in `STL Wait TimesTests/`
- **UI Tests**: Located in `STL Wait TimesUITests/`
- Run individual test files or full test suite via Xcode

### Dependencies
- **Swift Package Manager**: Dependencies are managed via SPM
- **SwiftSoup 2.9.5**: Used for HTML parsing (fallback API scraping)
- Resolve packages via Xcode or `File > Swift Packages > Resolve Package Versions`

## Architecture Overview

### MVVM Pattern with Combine
- **Models**: `Facility`, `WaitTime`, `CrowdLog` - Core data structures
- **ViewModels**: `FacilityListViewModel` - ObservableObject with @Published properties
- **Views**: SwiftUI views with reactive data binding via Combine
- **Services**: Singleton services for location, networking, and background tasks

### Key Services
- **LocationService**: Singleton managing CoreLocation, geo-fencing (75m radius), and facility sorting
- **WaitTimeService**: Multi-API integration with circuit breaker pattern, rate limiting (2s intervals), and fallback strategies
- **BackgroundTaskService**: BGTaskScheduler for 2-minute refresh cycles

### Data Flow
1. **FacilityListViewModel** coordinates between services and UI
2. **Auto-refresh timer** triggers every 2 minutes while app is active
3. **Background refresh** maintains data freshness when app is backgrounded
4. **Reactive updates** via Combine publishers update UI automatically

## API Integration Architecture

### Multi-Provider Support
- **Primary**: ClockwiseMD for Total Access Urgent Care (31 locations)
- **Secondary**: Solv for Mercy-GoHealth (25+ locations)
- **Planned**: Epic MyChart integration
- **Fallback**: Website scraping → CMS quarterly averages

### Error Handling Strategy
- Circuit breaker pattern for unstable APIs
- Graceful degradation through fallback chain
- Rate limiting to respect API quotas
- Comprehensive error types for different failure scenarios

## Location Services

### Geo-fencing Implementation
- **Proximity Detection**: 75-meter radius around facilities
- **Minimum Dwell Time**: 5 minutes before enabling crowd logging
- **Privacy-First**: Anonymous device hashing, no PII storage
- **Distance Calculation**: Real-time sorting by distance or wait time

## Background Processing

### Performance Requirements
- **Background Task Target**: ≤100ms CPU time per cycle
- **Refresh Interval**: 2 minutes for active app, background refresh when suspended
- **Data Freshness**: 8-hour staleness threshold with visual indicators

## Development Guidelines

### Code Organization
- Follow established MVVM pattern with clear separation of concerns
- Use Combine for reactive programming and data binding
- Implement comprehensive error handling with graceful degradation
- Maintain privacy-focused design (anonymous data collection only)

### Testing Strategy
- Unit tests should cover service layer business logic
- UI tests should verify critical user workflows
- Mock API responses for consistent testing
- Test background task scheduling and performance

### Location Permissions
- App requires location access for core functionality
- Handle permission states gracefully in UI
- Provide clear messaging about location usage

## Safety and Compliance

### Medical App Guidelines
- **Persistent 911 banner**: Always visible emergency disclaimer
- **Wait time disclaimers**: Clear messaging that times are estimates only
- **No medical advice**: App provides logistics only, not clinical guidance
- **HIPAA-adjacent compliance**: Anonymous data collection with device-only hashing

## Performance Considerations

### API Management
- **Batch processing**: Group API calls efficiently
- **Rate limiting**: Respect 2-second intervals between calls
- **Circuit breaker**: Automatically disable failing APIs temporarily
- **Caching strategy**: Balance data freshness with API quota conservation

### Background Tasks
- Target ≤100ms CPU time for background refresh
- Optimize for battery efficiency
- Handle background task expiration gracefully