# STL WaitLine - Healthcare Wait Time Tracker

A native iOS app that helps patients in the St. Louis metro area find the shortest wait times at emergency departments and urgent care centers.

## 🎯 Overview

STL WaitLine aggregates wait time data from multiple sources to help users make informed decisions about where to seek medical care for non-life-threatening issues. The app provides real-time wait times from urgent care APIs, crowd-sourced data, and CMS quarterly averages for emergency departments.

## ✨ Features

### Core Functionality
- **Real-time Wait Times**: Live data from Total Access Urgent Care via ClockwiseMD API
- **Dual Indicators for EDs**: CMS quarterly averages + crowd-sourced live data
- **Facility Toggle**: Switch between Emergency Departments and Urgent Care centers
- **Smart Sorting**: Sort by distance or wait time
- **Location-based**: Shows distances to facilities and enables geo-fenced logging

### Safety Features
- **Persistent 911 Banner**: Always reminds users to call 911 for emergencies
- **Medical Disclaimers**: Clear messaging that times are estimates only
- **HIPAA Compliant**: Anonymous data collection with no PII storage

### Data Sources
- **API Integration**: ClockwiseMD for Total Access Urgent Care real-time data
- **Crowd-sourced**: Anonymous user-submitted wait times with 2-hour decay
- **CMS Data**: Official quarterly averages for emergency departments

### User Experience
- **Detailed Charts**: 24-hour wait time trends using SwiftUI Charts
- **One-tap Actions**: Directions via Apple Maps, phone calls
- **Geo-fenced Logging**: Log wait times when within 75m of facility for 5+ minutes
- **Background Refresh**: Auto-updates every 2 minutes while active

## 🏗️ Architecture

### Tech Stack
- **Platform**: Native iOS 17+ with SwiftUI
- **Architecture**: MVVM pattern with Combine for reactive programming
- **Networking**: URLSession with Combine publishers
- **Location**: CoreLocation with geo-fencing
- **Charts**: SwiftUI Charts for 24-hour trends
- **Background**: BGAppRefreshTask for periodic updates

### Project Structure
```
STL Wait Times/
├── Models/
│   ├── Facility.swift          # Healthcare facility data model
│   ├── WaitTime.swift          # Wait time and API response models
│   └── CrowdLog.swift          # Anonymous crowd-sourced logging
├── Services/
│   ├── WaitTimeService.swift   # API integration and data management
│   ├── LocationService.swift   # GPS, distance, and geo-fencing
│   └── BackgroundTaskService.swift # Background refresh management
├── ViewModels/
│   └── FacilityListViewModel.swift # Main MVVM coordinator
├── Views/
│   ├── FacilityListView.swift  # Main list with toggle and sorting
│   └── FacilityDetailView.swift # Detail screen with charts and actions
└── Data/
    └── FacilityData.swift      # Static facility database
```

## 🏥 Covered Facilities

### Urgent Care Centers (with Real-time API)
- **Total Access Urgent Care** - Live wait times via ClockwiseMD API

### Emergency Departments (with CMS Data)
- Barnes-Jewish Hospital (CMS Avg: 137 min)
- Mercy Hospital St. Louis (CMS Avg: 124 min)
- St. Louis University Hospital (CMS Avg: 156 min)
- SSM Health Saint Louis University Hospital (CMS Avg: 142 min)
- BJC Christian Hospital (CMS Avg: 98 min)

### Additional Urgent Care Centers
- Urgent Care Plus - Clayton
- Concentra Urgent Care
- Mercy Urgent Care - Creve Coeur

## 🔧 API Integration

The app integrates with the ClockwiseMD API endpoint you provided:
```
https://api.clockwisemd.com/v1/hospitals/12604/waits
```

This provides real-time wait time data for Total Access Urgent Care, including:
- Current wait time in minutes
- Number of patients in line
- Last updated timestamp

## 🎨 User Interface

- **Clean, Medical-appropriate Design**: Professional appearance suitable for healthcare
- **Persistent Safety Warnings**: Always visible 911 disclaimer
- **Accessibility Compliant**: Supports Dynamic Type, VoiceOver, high contrast
- **Intuitive Navigation**: Simple two-level hierarchy (list → detail)

## 🔒 Privacy & Compliance

- **No PII Collection**: All user data is anonymous
- **Device-only Hashing**: Anonymous device IDs for deduplication
- **Secure API Calls**: HTTPS-only with proper error handling
- **HIPAA-adjacent Compliance**: Follows medical app guidelines

## 🚀 Getting Started

1. Open `STL Wait Times.xcodeproj` in Xcode 15+
2. Select iPhone simulator (iOS 17+)
3. Build and run (⌘+R)
4. Allow location permissions when prompted
5. Toggle between Emergency Departments and Urgent Care
6. Tap any facility for detailed information

## 📊 Success Metrics (Per PRD)

- **Accuracy Target**: ≤ ±20 min delta vs. on-site signage (80th percentile)
- **Retention Goal**: ≥ 25% week-4 retention for first-wave testers
- **Crowd Data Goal**: ≥ 200 validated submissions in first 60 days

## 🔮 Future Enhancements

- Additional urgent care API integrations
- Firebase backend for crowd data persistence
- Push notifications for wait time spikes
- Insurance network integration
- Expansion to other metro areas

## ⚠️ Important Notes

- **No Fake Data**: All wait times are real or clearly marked as estimates
- **Emergency Situations**: App always directs users to call 911 for emergencies
- **API Limitations**: Respect rate limits and handle graceful failures
- **Location Required**: Core functionality depends on location access

---

Built with ❤️ for the St. Louis healthcare community. This app helps patients make informed decisions while always prioritizing safety and emergency care when needed. 