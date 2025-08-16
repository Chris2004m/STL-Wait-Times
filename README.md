# STL Wait Times - Advanced 3D Healthcare Navigation App

A cutting-edge native iOS app that helps patients in the St. Louis metro area find the shortest wait times at emergency departments and urgent care centers using advanced 3D mapping and real-time data integration.

## 🎯 Overview

STL Wait Times combines sophisticated 3D mapping technology with real-time healthcare data to provide an immersive, user-friendly experience for finding medical care. The app features a Mapbox-powered 3D dashboard with dynamic lighting, satellite imagery, and comprehensive facility information to help users make informed healthcare decisions.

## ✨ Key Features

### 🗺️ Advanced 3D Mapping
- **Mapbox 3D Integration**: Professional-grade 3D mapping with buildings, terrain, and atmospheric effects
- **Dual Map Styles**: Toggle between Standard (3D buildings) and Satellite Streets (top-down imagery)
- **Dynamic Camera Controls**: Smooth fly-to animations, pitch control, and gesture-based navigation
- **Real-time Lighting**: Time-of-day adaptive lighting with sun positioning and shadows
- **Style-Adaptive UI**: Satellite mode disables pitch gestures and optimizes zoom for clarity

### 📍 Smart Location & Navigation  
- **Real-time Location Tracking**: GPS-based distance calculation and facility proximity
- **Apple Maps Integration**: One-tap navigation with turn-by-turn directions
- **Driving Time Calculation**: Real-time traffic-aware drive time estimates via Apple Maps
- **Geo-fenced Logging**: Automatic wait time logging when near facilities (75m radius, 5min minimum)
- **Location-based Sorting**: Facilities sorted by proximity to current location

### 🏥 Comprehensive Facility Data
- **Real-time API Integration**: Live wait times from Total Access Urgent Care via ClockwiseMD
- **Multi-source Data**: CMS quarterly averages for emergency departments + crowd-sourced updates
- **31+ Total Access Locations**: Complete coverage of St. Louis metro urgent care centers
- **Operating Hours**: Real-time open/closed status with detailed facility information
- **Interactive Selection**: Tap facilities on map to view details and navigate

### 📊 Rich Data Visualization
- **Dashboard Interface**: Flighty-inspired bottom sheet with peek/medium/expanded states
- **Wait Time Charts**: 24-hour trends using SwiftUI Charts
- **Color-coded Indicators**: Visual wait time representation (green/orange/red)
- **Real-time Updates**: Background refresh every 2 minutes with pull-to-refresh

### 🛡️ Safety & Compliance
- **Persistent 911 Banner**: Always-visible emergency care reminder
- **HIPAA Compliance**: Anonymous data collection with no PII storage
- **Medical Disclaimers**: Clear messaging that times are estimates
- **Accessibility Support**: VoiceOver, Dynamic Type, and high contrast support

## 🏗️ Architecture

### Tech Stack
- **Platform**: Native iOS 17+ with SwiftUI
- **Mapping**: Mapbox Maps SDK v11.13.3 with 3D rendering
- **Architecture**: MVVM with Combine reactive programming
- **Navigation**: MapboxNavigation v3.10.2 for route guidance  
- **Location**: CoreLocation with geo-fencing and MKDirections
- **Charts**: SwiftUI Charts for data visualization
- **Background**: BGAppRefreshTask for periodic updates

### Advanced Project Structure
```
STL Wait Times/
├── Models/
│   ├── Facility.swift          # Healthcare facility data model with operating hours
│   ├── WaitTime.swift          # Wait time responses and multi-source handling  
│   └── CrowdLog.swift          # Anonymous crowd-sourced logging system
├── Services/
│   ├── WaitTimeService.swift   # Multi-API integration with circuit breakers
│   ├── LocationService.swift   # GPS, geo-fencing, and driving time calculation
│   ├── BackgroundTaskService.swift # Background refresh coordination
│   └── NavigationManager.swift # Apple Maps integration and route handling
├── ViewModels/
│   └── FacilityListViewModel.swift # MVVM coordinator with reactive state
├── Views/
│   ├── DashboardView.swift     # Main 3D map dashboard with bottom sheet
│   ├── FlightyDashboardView.swift # Alternative dashboard layout
│   ├── MapboxView.swift        # Core 3D mapping component with dynamic styles
│   ├── FacilityListView.swift  # Facility list with smart sorting
│   ├── FacilityDetailView.swift # Detailed facility info with charts
│   └── UltimateMapbox3D/       # Advanced 3D mapping system
│       ├── UltimateMapbox3DView.swift # Enterprise-grade 3D mapping
│       ├── MapboxStyleManager.swift   # Dynamic style management
│       ├── MapboxCore3DEngine.swift   # 3D rendering engine
│       └── [8 additional 3D components]
├── Utils/
│   ├── MapboxDataConverter.swift # Annotation and route conversion
│   └── TAUCVerification.swift    # API endpoint validation
└── Data/
    └── FacilityData.swift      # Comprehensive facility database (31+ locations)
```

## 🏥 Covered Facilities

### Total Access Urgent Care (Real-time API Integration)
**31+ Locations with Live Data via ClockwiseMD API:**
- University City, Affton, Kirkwood North, Richmond Heights
- Creve Coeur, Sunset Hills, Des Peres, Clayton
- Bridgeton, Ferguson, Florissant, Maryland Heights  
- St. Peters, St. Charles, O'Fallon, Wentzville
- And 15+ additional metro locations with real-time wait times

### Emergency Departments (CMS Quarterly Data + Crowd-sourced)
- **Barnes-Jewish Hospital** (CMS Avg: 137 min)
- **Mercy Hospital St. Louis** (CMS Avg: 124 min) 
- **St. Louis University Hospital** (CMS Avg: 156 min)
- **SSM Health SLU Hospital** (CMS Avg: 142 min)
- **BJC Christian Hospital** (CMS Avg: 98 min)

### Additional Urgent Care Partners
- Urgent Care Plus locations
- Concentra Urgent Care centers  
- Mercy Urgent Care network

## 🔧 Advanced API Integration

### Multi-Endpoint ClockwiseMD Integration
```bash
# Primary API pattern for 31+ locations
https://api.clockwisemd.com/v1/hospitals/{hospital_id}/waits

# Example endpoints:
# University City: /hospitals/13598/waits
# Affton: /hospitals/12625/waits  
# Kirkwood: /hospitals/12624/waits
```

**Features:**
- Circuit breaker pattern prevents API abuse (3 failure threshold)
- Rate limiting (2-second intervals between calls)
- Robust error handling with graceful fallbacks
- Background refresh coordination across all endpoints
- Response parsing handles: single times, ranges, closed status

### Apple Maps Integration
- **MKDirections API**: Real-time driving time calculation with traffic
- **Batch Processing**: 5 facilities per batch with smart caching
- **Cache Management**: 1-hour expiry for driving time estimates
- **Turn-by-turn Navigation**: One-tap directions to any facility

## 🎨 Advanced User Interface

### 3D Map Dashboard  
- **Mapbox Standard/Satellite Toggle**: User-selectable map styles with persistent preferences
- **Dynamic 3D Camera**: Pitch control, smooth animations, and fly-to transitions
- **Time-based Lighting**: Adaptive sun positioning and atmospheric effects
- **Gesture Constraints**: Satellite mode locks to top-down view for optimal imagery

### Bottom Sheet Interface
- **Flighty-inspired Design**: Peek/Medium/Expanded states with smooth transitions
- **Smart Sheet Behavior**: Auto-adjusts based on content and user interaction
- **Accessibility Enhanced**: Full VoiceOver support with dynamic height adjustments

### Interactive Elements
- **Map Annotation Selection**: Tap facilities on 3D map to view details
- **Color-coded Wait Times**: Green (0-20min), Orange (21-45min), Red (46+min)
- **Real-time Status Indicators**: Live/API/Crowdsourced data source visualization
- **Driving Time Integration**: "2.1 mi • 🚗 5min" format with traffic awareness

## 🔒 Privacy & Security

- **HIPAA-Adjacent Compliance**: Anonymous data collection, no PII storage
- **Device-only Hashing**: Anonymous identifiers for deduplication
- **Secure HTTPS**: All API calls encrypted with certificate pinning
- **Location Privacy**: GPS data never transmitted, only used locally
- **Transparent Data Sources**: Clear labeling of live vs estimated data

## 🚀 Setup & Requirements

### Development Environment
```bash
# Requirements
- Xcode 15+ with iOS 17+ SDK
- Mapbox access token (configured in MapboxView.swift)
- Swift Package Manager dependencies auto-resolved

# Quick Start
1. Clone repository
2. Open STL Wait Times.xcodeproj 
3. Select iPhone simulator (iOS 17+)
4. Build and run (⌘+R)
5. Grant location permissions for full functionality
```

### Key Dependencies
- **MapboxMaps** v11.13.3: 3D mapping and navigation
- **MapboxNavigation** v3.10.2: Route guidance integration
- **SwiftUI Charts**: Data visualization framework
- **Combine**: Reactive programming framework

## 📊 Performance & Metrics

### Technical Performance
- **3D Rendering**: 60fps target with adaptive quality scaling  
- **Memory Management**: Efficient annotation clustering and layer management
- **Network Efficiency**: Batched API calls with intelligent rate limiting
- **Battery Optimization**: Background location updates only when necessary

### Success Metrics
- **Wait Time Accuracy**: ≤ ±20 min delta target (80th percentile)
- **User Retention**: 25%+ week-4 retention goal for beta testers  
- **Data Coverage**: 200+ crowd-sourced submissions target (first 60 days)
- **App Store Rating**: 4.5+ stars with healthcare-focused reviews

## 🔮 Roadmap & Future Enhancements

### Short-term (Next Release)
- Firebase backend integration for persistent crowd data
- Push notifications for significant wait time changes
- Enhanced accessibility features and voice navigation
- Insurance network filtering and compatibility checks

### Long-term Vision  
- **Multi-city Expansion**: Kansas City, Chicago, Denver metro areas
- **AI-powered Predictions**: Machine learning wait time forecasting
- **Healthcare Network Integration**: Direct EHR and scheduling system APIs
- **AR Navigation**: Indoor wayfinding for large hospital complexes

## ⚠️ Critical Safety Notes

- **Emergency Care Priority**: App prominently displays 911 for emergencies
- **Data Accuracy Disclaimer**: All wait times are estimates; call ahead when possible  
- **Medical Advice Limitation**: App provides facility information only, not medical guidance
- **Location Dependency**: Core features require location access for accurate results

---

**Built for the St. Louis Healthcare Community**

This app leverages cutting-edge 3D mapping technology and real-time data integration to help patients make informed healthcare decisions while maintaining the highest standards of safety, privacy, and accessibility. 