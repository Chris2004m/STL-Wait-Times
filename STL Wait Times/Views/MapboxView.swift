//
//  MapboxView.swift
//  STL Wait Times
//
//  Created by Claude AI on 7/15/25.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Compatibility Map View
// This will be replaced with full Mapbox implementation once SDK is added
struct MapboxView: View {
    
    // MARK: - Properties
    @Binding var coordinateRegion: MKCoordinateRegion
    var annotations: [CustomMapAnnotation] = []
    var mapStyle: String = "standard"
    var onMapTap: ((CLLocationCoordinate2D) -> Void)?
    
    var body: some View {
        // Temporary MapKit implementation - will be replaced with Mapbox
        Map(coordinateRegion: $coordinateRegion, annotationItems: annotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                Circle()
                    .fill(Color(annotation.color))
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 16, height: 16)
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .onTapGesture { location in
            // Convert tap location to coordinate (approximation)
            onMapTap?(coordinateRegion.center)
        }
    }
}

// MARK: - Supporting Types
struct CustomMapAnnotation: Identifiable, Equatable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let color: UIColor
    let title: String?
    let subtitle: String?
    
    init(id: String, 
         coordinate: CLLocationCoordinate2D, 
         color: UIColor, 
         title: String? = nil, 
         subtitle: String? = nil) {
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