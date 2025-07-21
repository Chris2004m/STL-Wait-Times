#!/usr/bin/env swift

// Test script to verify driving time functionality works correctly

import Foundation
import CoreLocation
import MapKit

// Test coordinates (St. Louis area)
let testUserLocation = CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994) // St. Louis center
let testFacilityLocation = CLLocationCoordinate2D(latitude: 38.6478, longitude: -90.2025) // Clayton area

print("🧪 Testing Apple Maps MKDirections API")
print("📍 User location: \(testUserLocation.latitude), \(testUserLocation.longitude)")
print("🏥 Facility location: \(testFacilityLocation.latitude), \(testFacilityLocation.longitude)")
print("")

// Create MKDirections request
let request = MKDirections.Request()
request.source = MKMapItem(placemark: MKPlacemark(coordinate: testUserLocation))
request.destination = MKMapItem(placemark: MKPlacemark(coordinate: testFacilityLocation))
request.transportType = .automobile
request.requestsAlternateRoutes = false

let directions = MKDirections(request: request)

directions.calculate { response, error in
    defer {
        CFRunLoopStop(CFRunLoopGetCurrent())
    }
    
    if let error = error {
        print("❌ Failed to calculate driving time: \(error.localizedDescription)")
        print("This indicates an issue with the MKDirections API")
        return
    }
    
    guard let route = response?.routes.first else {
        print("❌ No route found")
        print("This could indicate network issues or invalid coordinates")
        return
    }
    
    let travelTime = route.expectedTravelTime
    let minutes = Int(travelTime / 60)
    let distance = route.distance / 1000 // Convert to kilometers
    
    print("✅ SUCCESS! Apple Maps API is working correctly")
    print("🚗 Driving time: \(minutes) minutes")
    print("📏 Distance: \(String(format: "%.1f", distance)) km")
    print("")
    print("This confirms that:")
    print("  - MKDirections API is accessible")
    print("  - Your network connection is working")
    print("  - The driving time calculation logic should work in your app")
    print("")
    print("If you're still not seeing driving times in your app, the issue is likely:")
    print("  1. Location permissions not granted")
    print("  2. Calculations not being triggered at the right time")
    print("  3. UI not updating when calculations complete")
    print("")
    print("Check the console logs in your app for debugging messages that start with 🚗")
}

// Run the event loop
CFRunLoopRun()