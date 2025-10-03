//
//  MapTypes.swift
//  STL Wait Times
//
//  Shared map-related types and annotations
//

import Foundation
import CoreLocation
import UIKit

// MARK: - Custom Map Annotation

/// Custom map annotation for medical facilities
struct CustomMapAnnotation: Identifiable, Equatable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let color: UIColor
    let title: String?
    let subtitle: String?
    
    init(
        id: String,
        coordinate: CLLocationCoordinate2D,
        color: UIColor,
        title: String? = nil,
        subtitle: String? = nil
    ) {
        self.id = id
        self.coordinate = coordinate
        self.color = color
        self.title = title
        self.subtitle = subtitle
    }
    
    static func == (lhs: CustomMapAnnotation, rhs: CustomMapAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Map Display Mode

/// Map display modes for different visualization styles
enum MapDisplayMode {
    case standard2D
    case hybrid2D
    case satellite2D
    case buildings3D
    case terrain3D
}

// MARK: - Extensions

/// Extension for coordinate distance calculation
extension CLLocationCoordinate2D {
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
}
