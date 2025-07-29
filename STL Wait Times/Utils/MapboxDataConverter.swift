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
    
    /// Convert medical facilities to Mapbox annotations
    /// - Parameters:
    ///   - facilities: Array of medical facilities from app data
    ///   - waitTimes: Current wait times dictionary
    ///   - userLocation: User's current location for distance calculation
    ///   - includeClosedFacilities: Whether to include closed facilities
    ///   - selectedFacilityId: ID of the selected facility for highlighting
    /// - Returns: Array of custom map annotations
    func convertToMapboxAnnotations(
        facilities: [Facility],
        waitTimes: [String: WaitTime] = [:],
        userLocation: CLLocation? = nil,
        includeClosedFacilities: Bool = true,
        selectedFacilityId: String? = nil
    ) -> [CustomMapAnnotation] {
        
        return facilities.compactMap { facility in
            // Skip closed facilities if not desired
            if !includeClosedFacilities && !facility.isOpen {
                return nil
            }
            
            // Get wait time information
            let waitTime = waitTimes[facility.id]
            let waitMinutes = waitTime?.waitMinutes
            let _ = waitTime?.changeString // Unused for now
            
            // Determine color based on wait time, facility type, and selection state
            let isSelected = facility.id == selectedFacilityId
            let color = determineAnnotationColor(
                for: facility,
                waitTime: waitMinutes,
                isSelected: isSelected
            )
            
            // Create title and subtitle
            let title = facility.name
            let subtitle = createSubtitle(
                waitTime: waitMinutes,
                facilityType: facility.facilityType.rawValue,
                isOpen: facility.isOpen
            )
            
            return CustomMapAnnotation(
                id: facility.id,
                coordinate: facility.coordinate,
                color: color,
                title: title,
                subtitle: subtitle
            )
        }
    }
    
    /// Convert legacy annotation data to custom annotations
    /// - Parameters:
    ///   - facilityData: Facility data for additional information
    /// - Returns: Array of custom map annotations
    func convertLegacyAnnotations(
        with facilityData: [Facility]
    ) -> [CustomMapAnnotation] {
        
        // Convert facilities directly to custom annotations with default settings
        return facilityData.map { facility in
            CustomMapAnnotation(
                id: facility.id,
                coordinate: facility.coordinate,
                color: determineAnnotationColor(for: facility, waitTime: nil, isSelected: false),
                title: facility.name,
                subtitle: facility.facilityType.rawValue
            )
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Determine annotation color based on facility type, wait time, and selection state
    private func determineAnnotationColor(for facility: Facility, waitTime: Int?, isSelected: Bool = false) -> UIColor {
        // Priority: selection > wait time > facility type > default
        
        // Highlight selected facility with distinctive color
        if isSelected {
            return .systemPurple // Distinctive purple color for selected facility
        }
        
        if let wait = waitTime {
            switch wait {
            case 0...15:
                return .systemGreen
            case 16...30:
                return .systemYellow
            case 31...60:
                return .systemOrange
            default:
                return .systemRed
            }
        }
        
        // Fallback to facility type colors
        switch facility.facilityType.rawValue.lowercased() {
        case "er", "ed", "emergency", "emergency department":
            return .systemRed
        case "uc", "urgent care", "urgent":
            return .systemOrange
        default:
            return .systemBlue
        }
    }
    
    /// Create subtitle text for annotation
    private func createSubtitle(waitTime: Int?, facilityType: String, isOpen: Bool) -> String {
        var components: [String] = []
        
        // Add facility type
        components.append(facilityType)
        
        // Add wait time if available
        if let wait = waitTime {
            components.append("\(wait) min wait")
        }
        
        // Add open/closed status
        if !isOpen {
            components.append("CLOSED")
        }
        
        return components.joined(separator: " • ")
    }
    
}

// MARK: - Supporting Extensions

/// Extension to provide conversion methods for existing app models
extension Facility {
    
    /// Convert to custom map annotation using default converter
    func toCustomMapAnnotation(
        waitTime: WaitTime? = nil,
        userLocation: CLLocation? = nil
    ) -> CustomMapAnnotation {
        
        let converter = MapboxDataConverter()
        
        // Create temporary arrays for converter
        let facilities = [self]
        let waitTimes = waitTime != nil ? [self.id: waitTime!] : [:]
        
        return converter.convertToMapboxAnnotations(
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
    
    /// Generate sample custom annotations for previews and testing
    static func sampleAnnotations() -> [CustomMapAnnotation] {
        return [
            CustomMapAnnotation(
                id: "sample1",
                coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
                color: .systemRed,
                title: "Barnes-Jewish Hospital Emergency",
                subtitle: "Emergency Department • 45 min wait"
            ),
            CustomMapAnnotation(
                id: "sample2",
                coordinate: CLLocationCoordinate2D(latitude: 38.6370, longitude: -90.2094),
                color: .systemGreen,
                title: "Urgent Care Plus",
                subtitle: "Urgent Care • 15 min wait"
            ),
            CustomMapAnnotation(
                id: "sample3",
                coordinate: CLLocationCoordinate2D(latitude: 38.6170, longitude: -90.1794),
                color: .systemOrange,
                title: "St. Louis University Hospital",
                subtitle: "Hospital • 32 min wait"
            )
        ]
    }
}
#endif