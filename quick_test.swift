#!/usr/bin/env swift

import Foundation
import CoreLocation

// Quick test to verify location setup
print("🧪 Quick location test")

// Test the St. Louis location we set in the simulator
let stlLocation = CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994)
print("📍 Test location: \(stlLocation.latitude), \(stlLocation.longitude)")

// Check if this is a valid location
let testLocation = CLLocation(latitude: stlLocation.latitude, longitude: stlLocation.longitude)
print("📍 CLLocation created: \(testLocation)")

// Test distance calculation to a facility
let facilityLocation = CLLocationCoordinate2D(latitude: 38.6478, longitude: -90.2025) // Clayton area
let facility = CLLocation(latitude: facilityLocation.latitude, longitude: facilityLocation.longitude)

let distance = testLocation.distance(from: facility)
print("📏 Distance to test facility: \(distance) meters (\(String(format: "%.1f", distance/1000)) km)")

print("✅ Location test complete")