//
//  AppleMapsView.swift
//  STL Wait Times
//
//  Stable Apple Maps integration backed by MKMapView.
//

import SwiftUI
import MapKit
import CoreLocation

/// Configuration for Apple Maps view appearance and behavior
enum AppleMapStyle: String, CaseIterable {
    case standard = "Standard"
    case satellite = "Satellite"
    case hybrid = "Hybrid"

    var displayName: String { rawValue }
}

/// Apple Maps view with map styles, facility annotations, recentering, and optional route overlay.
struct AppleMapsView: UIViewRepresentable {

    // MARK: - Properties

    @Binding var coordinateRegion: MKCoordinateRegion
    var annotations: [CustomMapAnnotation]
    var mapStyle: AppleMapStyle
    var showsUserLocation: Bool
    var onMapTap: ((CLLocationCoordinate2D) -> Void)?
    var recenterTrigger: UUID?
    var selectedFacilityId: String?
    var routePolyline: MKPolyline?

    // MARK: - UIViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.pointOfInterestFilter = .includingAll

        applyMapStyle(to: mapView)

        context.coordinator.isProgrammaticRegionChange = true
        mapView.setRegion(coordinateRegion, animated: false)
        context.coordinator.isProgrammaticRegionChange = false
        context.coordinator.lastRecenterTrigger = recenterTrigger

        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tapRecognizer)

        context.coordinator.mapView = mapView
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.mapView = mapView

        mapView.showsUserLocation = showsUserLocation
        applyMapStyle(to: mapView)

        syncRegion(on: mapView, with: context.coordinator)
        syncAnnotations(on: mapView)
        syncRouteOverlay(on: mapView, with: context.coordinator)
        context.coordinator.applySelection(selectedFacilityId)
    }

    // MARK: - Private Helpers

    private func applyMapStyle(to mapView: MKMapView) {
        switch mapStyle {
        case .standard:
            mapView.mapType = .standard
        case .satellite:
            mapView.mapType = .satellite
        case .hybrid:
            mapView.mapType = .hybrid
        }
    }

    private func syncRegion(on mapView: MKMapView, with coordinator: Coordinator) {
        let shouldAnimate = recenterTrigger != nil && recenterTrigger != coordinator.lastRecenterTrigger
        coordinator.lastRecenterTrigger = recenterTrigger

        guard !mapView.region.isApproximatelyEqual(to: coordinateRegion) else { return }

        coordinator.isProgrammaticRegionChange = true
        mapView.setRegion(coordinateRegion, animated: shouldAnimate)
        DispatchQueue.main.async {
            coordinator.isProgrammaticRegionChange = false
        }
    }

    private func syncAnnotations(on mapView: MKMapView) {
        let existing = mapView.annotations.compactMap { $0 as? FacilityAnnotation }
        let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.facilityId, $0) })
        let incomingById = Dictionary(uniqueKeysWithValues: annotations.map { ($0.id, $0) })

        let idsToRemove = Set(existingById.keys).subtracting(incomingById.keys)
        let idsToAdd = Set(incomingById.keys).subtracting(existingById.keys)

        if !idsToRemove.isEmpty {
            let toRemove = existing.filter { idsToRemove.contains($0.facilityId) }
            mapView.removeAnnotations(toRemove)
        }

        for id in idsToAdd {
            guard let model = incomingById[id] else { continue }
            let annotation = FacilityAnnotation(model: model)
            mapView.addAnnotation(annotation)
        }

        for (id, model) in incomingById {
            guard let current = existingById[id] else { continue }
            if current.coordinate.latitude != model.coordinate.latitude || current.coordinate.longitude != model.coordinate.longitude {
                current.coordinate = model.coordinate
            }
            current.title = model.title
            current.subtitle = model.subtitle
            current.markerColor = model.color
        }
    }

    private func syncRouteOverlay(on mapView: MKMapView, with coordinator: Coordinator) {
        let existingPolylines = mapView.overlays.compactMap { $0 as? MKPolyline }

        guard let routePolyline else {
            if !existingPolylines.isEmpty {
                mapView.removeOverlays(existingPolylines)
            }
            coordinator.routeSignature = nil
            return
        }

        let signature = Self.signature(for: routePolyline)
        guard signature != coordinator.routeSignature else { return }

        if !existingPolylines.isEmpty {
            mapView.removeOverlays(existingPolylines)
        }
        mapView.addOverlay(routePolyline)
        coordinator.routeSignature = signature
    }

    private static func signature(for polyline: MKPolyline) -> String {
        guard polyline.pointCount > 0 else { return "0" }

        var coordinates = [CLLocationCoordinate2D](repeating: .init(latitude: 0, longitude: 0), count: polyline.pointCount)
        polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: polyline.pointCount))

        guard let first = coordinates.first, let last = coordinates.last else {
            return "\(polyline.pointCount)"
        }

        return "\(polyline.pointCount)-\(first.latitude)-\(first.longitude)-\(last.latitude)-\(last.longitude)"
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: AppleMapsView
        weak var mapView: MKMapView?
        var isProgrammaticRegionChange = false
        var lastRecenterTrigger: UUID?
        var routeSignature: String?

        init(parent: AppleMapsView) {
            self.parent = parent
        }

        @objc func handleMapTap(_ recognizer: UITapGestureRecognizer) {
            guard let mapView = recognizer.view as? MKMapView else { return }
            let point = recognizer.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            parent.onMapTap?(coordinate)
        }

        func applySelection(_ selectedFacilityId: String?) {
            guard let mapView else { return }

            let facilityAnnotations = mapView.annotations.compactMap { $0 as? FacilityAnnotation }

            if let selectedFacilityId,
               let annotation = facilityAnnotations.first(where: { $0.facilityId == selectedFacilityId }) {
                if mapView.selectedAnnotations.first(where: { ($0 as? FacilityAnnotation)?.facilityId == selectedFacilityId }) == nil {
                    mapView.selectAnnotation(annotation, animated: true)
                }
            } else if !mapView.selectedAnnotations.isEmpty {
                mapView.selectedAnnotations.forEach { mapView.deselectAnnotation($0, animated: true) }
            }

            // Refresh marker styling to keep selected marker visually emphasized.
            for annotation in facilityAnnotations {
                if let view = mapView.view(for: annotation) as? MKMarkerAnnotationView {
                    let isSelected = annotation.facilityId == selectedFacilityId
                    view.displayPriority = isSelected ? .required : .defaultHigh
                    view.transform = isSelected ? CGAffineTransform(scaleX: 1.12, y: 1.12) : .identity
                }
            }
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            guard !isProgrammaticRegionChange else { return }

            let region = mapView.region
            DispatchQueue.main.async {
                self.parent.coordinateRegion = region
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }

            guard let facility = annotation as? FacilityAnnotation else {
                return nil
            }

            let identifier = "FacilityMarker"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)

            view.annotation = annotation
            view.canShowCallout = false
            view.titleVisibility = .hidden
            view.subtitleVisibility = .hidden
            view.markerTintColor = facility.markerColor
            view.glyphImage = UIImage(systemName: "cross.fill")
            view.glyphTintColor = .white

            let isSelected = facility.facilityId == parent.selectedFacilityId
            view.displayPriority = isSelected ? .required : .defaultHigh
            view.transform = isSelected ? CGAffineTransform(scaleX: 1.12, y: 1.12) : .identity

            return view
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 7
                renderer.lineJoin = .round
                renderer.lineCap = .round
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

private final class FacilityAnnotation: MKPointAnnotation {
    let facilityId: String
    var markerColor: UIColor

    init(model: CustomMapAnnotation) {
        self.facilityId = model.id
        self.markerColor = model.color
        super.init()
        self.coordinate = model.coordinate
        self.title = model.title
        self.subtitle = model.subtitle
    }
}

private extension MKCoordinateRegion {
    func isApproximatelyEqual(to other: MKCoordinateRegion, epsilon: CLLocationDegrees = 0.0005) -> Bool {
        abs(center.latitude - other.center.latitude) < epsilon &&
        abs(center.longitude - other.center.longitude) < epsilon &&
        abs(span.latitudeDelta - other.span.latitudeDelta) < epsilon &&
        abs(span.longitudeDelta - other.span.longitudeDelta) < epsilon
    }
}

#Preview {
    @Previewable @State var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    let sampleAnnotations = [
        CustomMapAnnotation(
            id: "1",
            coordinate: CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
            color: .systemRed,
            title: "Barnes-Jewish Hospital",
            subtitle: "Emergency Department"
        ),
        CustomMapAnnotation(
            id: "2",
            coordinate: CLLocationCoordinate2D(latitude: 38.6470, longitude: -90.2394),
            color: .systemGreen,
            title: "Urgent Care Plus",
            subtitle: "15 min wait"
        )
    ]

    return AppleMapsView(
        coordinateRegion: $region,
        annotations: sampleAnnotations,
        mapStyle: .standard,
        showsUserLocation: true
    )
}
