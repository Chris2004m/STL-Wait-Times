//
//  MapboxDataConverter.swift
//  STL Wait Times
//
//  Data conversion utilities for 3D Mapbox integration
//  Created by Claude AI on 7/15/25.
//

import Foundation
import CoreLocation
import SwiftUI

/// **MapboxDataConverter**: Utility class for converting existing app data to 3D Mapbox annotations
///
/// This converter bridges the existing medical facility data model with the enhanced
/// 3D annotation system, providing intelligent mapping of facility types, priorities,
/// and visual characteristics.
///
/// **Features:**
/// - Automatic facility type detection and categorization
/// - Wait time-based priority calculation
/// - Distance-aware visual scaling
/// - Accessibility-compliant color and icon selection
///
/// **Usage:**
/// ```swift
/// let converter = MapboxDataConverter()
/// let annotations3D = converter.convertToMapbox3DAnnotations(
///     facilities: facilityData,
///     waitTimes: currentWaitTimes,
///     userLocation: userLocation
/// )
/// ```
class MapboxDataConverter {
    
    // MARK: - Constants
    
    /// Default building heights for different facility types (in meters)
    private enum DefaultBuildingHeights {
        static let emergencyDepartment: Double = 80.0
        static let urgentCare: Double = 25.0
        static let hospital: Double = 120.0
        static let clinics: Double = 15.0
    }
    
    /// Priority calculation thresholds
    private enum PriorityThresholds {
        static let criticalWaitTime: Int = 60  // minutes
        static let highWaitTime: Int = 45
        static let mediumWaitTime: Int = 20
        static let maxDistance: Double = 10000.0  // meters
    }
    
    // MARK: - Main Conversion Methods
    
    /// Convert medical facilities to 3D Mapbox annotations
    /// - Parameters:
    ///   - facilities: Array of medical facilities from app data
    ///   - waitTimes: Current wait times dictionary
    ///   - userLocation: User's current location for distance calculation
    ///   - includeClosedFacilities: Whether to include closed facilities
    /// - Returns: Array of 3D-enhanced annotations
    func convertToMapbox3DAnnotations(
        facilities: [Facility],
        waitTimes: [String: WaitTime] = [:],
        userLocation: CLLocation? = nil,
        includeClosedFacilities: Bool = true
    ) -> [MedicalFacility3DAnnotation] {
        
        return facilities.compactMap { facility in
            // Skip closed facilities if not desired
            if !includeClosedFacilities && !facility.isOpen {
                return nil
            }
            
            // Get wait time information
            let waitTime = waitTimes[facility.id]
            let waitMinutes = waitTime?.waitMinutes
            let waitChange = waitTime?.changeString
            
            // Calculate distance string
            let distanceString = calculateDistanceString(
                to: facility,
                from: userLocation
            )
            
            // Determine facility type
            let facilityType = mapFacilityType(facility.facilityType.rawValue)
            
            // Calculate priority level
            let priority = calculatePriorityLevel(
                for: facility,
                waitTime: waitMinutes,
                userLocation: userLocation
            )
            
            // Determine building height
            let buildingHeight = determineBuildingHeight(
                facilityType: facilityType,
                facility: facility
            )
            
            return MedicalFacility3DAnnotation(
                id: facility.id,
                coordinate: facility.coordinate,
                name: facility.name,
                facilityType: facilityType,
                waitTime: waitMinutes,
                waitTimeChange: waitChange,
                distance: distanceString,
                isOpen: facility.isOpen,
                buildingHeight: buildingHeight,
                priorityLevel: priority,
                customIcon: selectCustomIcon(for: facility)
            )
        }
    }
    
    /// Convert legacy annotation data to 3D annotations
    /// - Parameters:
    ///   - annotations: Existing legacy map annotations
    ///   - facilityData: Facility data for additional information
    /// - Returns: Array of 3D annotations
    func convertLegacyAnnotations(
        with facilityData: [Facility]
    ) -> [MedicalFacility3DAnnotation] {
        
        // Convert facilities directly to 3D annotations with default settings
        return facilityData.map { facility in
            MedicalFacility3DAnnotation(
                id: facility.id,
                coordinate: facility.coordinate,
                name: facility.name,
                facilityType: mapFacilityType(facility.facilityType.rawValue),
                waitTime: nil,
                waitTimeChange: nil,
                distance: nil,
                isOpen: facility.isOpen,
                buildingHeight: DefaultBuildingHeights.hospital,
                priorityLevel: .medium,
                customIcon: nil
            )
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Map internal facility type to 3D annotation facility type
    private func mapFacilityType(_ type: String) -> MedicalFacility3DAnnotation.FacilityType {
        switch type.lowercased() {
        case "er", "ed", "emergency", "emergency department":
            return .emergencyDepartment
        case "uc", "urgent care", "urgent":
            return .urgentCare
        default:
            return .hospital
        }
    }
    
    /// Calculate priority level based on multiple factors
    private func calculatePriorityLevel(
        for facility: Facility,
        waitTime: Int?,
        userLocation: CLLocation?
    ) -> MedicalFacility3DAnnotation.PriorityLevel {
        
        var priorityScore = 0
        
        // Wait time factor (lower wait time = higher priority)
        if let wait = waitTime {
            if wait >= PriorityThresholds.criticalWaitTime {
                priorityScore -= 2
            } else if wait >= PriorityThresholds.highWaitTime {
                priorityScore -= 1
            } else if wait <= PriorityThresholds.mediumWaitTime {
                priorityScore += 2
            } else {
                priorityScore += 1
            }
        }
        
        // Distance factor (closer = higher priority)
        if let userLoc = userLocation {
            let facilityLocation = CLLocation(
                latitude: facility.coordinate.latitude,
                longitude: facility.coordinate.longitude
            )
            let distance = userLoc.distance(from: facilityLocation)
            
            if distance <= 1000 { // Within 1km
                priorityScore += 2
            } else if distance <= 5000 { // Within 5km
                priorityScore += 1
            } else if distance >= PriorityThresholds.maxDistance {
                priorityScore -= 1
            }
        }
        
        // Facility type factor
        switch facility.facilityType.rawValue.lowercased() {
        case "ed", "emergency", "emergency department":
            priorityScore += 1 // Emergency departments are important
        case "uc", "urgent care":
            priorityScore += 0 // Neutral
        default:
            priorityScore -= 1 // General hospitals lower priority for urgent needs
        }
        
        // Open/closed status
        if !facility.isOpen {
            priorityScore -= 3
        }
        
        // Map score to priority level
        switch priorityScore {
        case 4...:
            return .critical
        case 2...3:
            return .high
        case 0...1:
            return .medium
        default:
            return .low
        }
    }
    
    /// Determine building height for 3D visualization
    private func determineBuildingHeight(
        facilityType: MedicalFacility3DAnnotation.FacilityType,
        facility: Facility
    ) -> Double {
        
        // Base height by facility type
        var height: Double
        
        switch facilityType {
        case .emergencyDepartment:
            height = DefaultBuildingHeights.emergencyDepartment
        case .urgentCare:
            height = DefaultBuildingHeights.urgentCare
        case .hospital:
            height = DefaultBuildingHeights.hospital
        case .clinic:
            height = DefaultBuildingHeights.clinics
        case .pharmacy:
            height = DefaultBuildingHeights.clinics
        }
        
        // Adjust based on facility name (heuristic for size)
        let name = facility.name.lowercased()
        
        if name.contains("medical center") || name.contains("hospital") {
            height *= 1.2 // Larger buildings
        } else if name.contains("clinic") || name.contains("care center") {
            height *= 0.8 // Smaller buildings
        }
        
        // Add some variation for visual interest
        let variation = Double.random(in: 0.9...1.1)
        return height * variation
    }
    
    /// Calculate distance string from user location
    private func calculateDistanceString(
        to facility: Facility,
        from userLocation: CLLocation?
    ) -> String? {
        
        guard let userLoc = userLocation else { return nil }
        
        let facilityLocation = CLLocation(
            latitude: facility.coordinate.latitude,
            longitude: facility.coordinate.longitude
        )
        
        let distance = userLoc.distance(from: facilityLocation)
        
        // Format distance appropriately
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            let km = distance / 1000.0
            return String(format: "%.1fkm", km)
        }
    }
    
    /// Select custom icon for facility if needed
    private func selectCustomIcon(for facility: Facility) -> String? {
        // Return nil to use default icons
        // Could be extended for specific facility branding
        return nil
    }
}

// MARK: - Supporting Extensions

/// Extension to provide conversion methods for existing app models
extension Facility {
    
    /// Convert to 3D annotation using default converter
    func toMapbox3DAnnotation(
        waitTime: WaitTime? = nil,
        userLocation: CLLocation? = nil
    ) -> MedicalFacility3DAnnotation {
        
        let converter = MapboxDataConverter()
        
        // Create temporary arrays for converter
        let facilities = [self]
        let waitTimes = waitTime != nil ? [self.id: waitTime!] : [:]
        
        return converter.convertToMapbox3DAnnotations(
            facilities: facilities,
            waitTimes: waitTimes,
            userLocation: userLocation
        ).first!
    }
}


// MARK: - Model Extensions for Compatibility

/// Extension to Facility model for 3D conversion compatibility
extension Facility {
    /// Check if facility is open (placeholder implementation)
    var isOpen: Bool {
        return true // TODO: Implement actual open/closed logic
    }
}

// MARK: - Extensions for existing models

/// Extension for wait time change string generation  
extension WaitTime {
    
    /// Generate user-friendly change string for 3D annotations
    var changeString: String {
        // Generate change string based on wait time trends
        // This is a placeholder - in a real implementation, you would track
        // wait time history and calculate actual changes
        if waitMinutes <= 15 {
            return "Stable"
        } else if waitMinutes <= 30 {
            return "+5 min"
        } else {
            return "+10 min"
        }
    }
}

#if DEBUG
// MARK: - Preview Data

extension MapboxDataConverter {
    
    /// Generate sample 3D annotations for previews and testing
    static func sampleAnnotations() -> [MedicalFacility3DAnnotation] {
        return [
            MedicalFacility3DAnnotation(
                id: "sample1",
                coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
                name: "Barnes-Jewish Hospital Emergency",
                facilityType: .emergencyDepartment,
                waitTime: 45,
                waitTimeChange: "+5 min",
                distance: "2.3 mi",
                isOpen: true,
                buildingHeight: 100.0,
                priorityLevel: .high,
                customIcon: nil
            ),
            MedicalFacility3DAnnotation(
                id: "sample2",
                coordinate: CLLocationCoordinate2D(latitude: 38.6370, longitude: -90.2094),
                name: "Urgent Care Plus",
                facilityType: .urgentCare,
                waitTime: 15,
                waitTimeChange: "-2 min",
                distance: "1.8 mi",
                isOpen: true,
                buildingHeight: 25.0,
                priorityLevel: .medium,
                customIcon: nil
            ),
            MedicalFacility3DAnnotation(
                id: "sample3",
                coordinate: CLLocationCoordinate2D(latitude: 38.6170, longitude: -90.1794),
                name: "St. Louis University Hospital",
                facilityType: .hospital,
                waitTime: 32,
                waitTimeChange: "Same",
                distance: "3.1 mi",
                isOpen: true,
                buildingHeight: 120.0,
                priorityLevel: .medium,
                customIcon: nil
            )
        ]
    }
}
#endif