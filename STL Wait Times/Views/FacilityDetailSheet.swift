//
//  FacilityDetailSheet.swift
//  STL Wait Times
//
//  Apple Maps-style facility detail popup
//

import SwiftUI
import MapKit

/// Apple Maps-style detail sheet for facility information
struct FacilityDetailSheet: View {
    let facility: Facility
    let waitTime: String?
    let onNavigate: () -> Void
    let onDismiss: () -> Void
    
    @StateObject private var locationService = LocationService.shared
    @State private var distance: String = "Calculating..."
    @State private var drivingTime: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with name and type
                    VStack(alignment: .leading, spacing: 8) {
                        Text(facility.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Image(systemName: facility.facilityType == .emergencyDepartment ? "cross.circle.fill" : "cross.case.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                            
                            Text(facility.facilityType.displayName)
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // Status badge
                            statusBadge
                        }
                    }
                    
                    Divider()
                    
                    // Wait time card
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Wait Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(waitTime ?? "N/A")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(waitTimeColor)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Distance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(distance)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            if let drivingTime = drivingTime {
                                HStack(spacing: 4) {
                                    Image(systemName: "car.fill")
                                        .font(.system(size: 12))
                                    Text(drivingTime)
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Divider()
                    
                    // Address and phone
                    VStack(alignment: .leading, spacing: 12) {
                        infoRow(icon: "mappin.circle.fill", title: "Address", value: facility.fullAddress)
                        infoRow(icon: "phone.circle.fill", title: "Phone", value: facility.phone)
                        if let hours = facility.operatingHours {
                            infoRow(icon: "clock.fill", title: "Hours", value: formatHours(hours))
                        } else {
                            infoRow(icon: "clock.fill", title: "Hours", value: "Open 24 hours")
                        }
                    }
                    
                    // Navigation button
                    Button(action: onNavigate) {
                        HStack {
                            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                .font(.system(size: 20))
                            Text("Start Navigation")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            calculateDistance()
            fetchDrivingTime()
        }
    }
    
    // MARK: - Subviews
    
    private var statusBadge: some View {
        Text(facility.isCurrentlyOpen ? "Open" : "Closed")
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(facility.isCurrentlyOpen ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
            .foregroundColor(facility.isCurrentlyOpen ? .green : .red)
            .cornerRadius(6)
    }
    
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var waitTimeColor: Color {
        guard let time = waitTime, time != "N/A" else { return .gray }
        
        if let minutes = Int(time.replacingOccurrences(of: " min", with: "")) {
            if minutes <= 15 {
                return .green
            } else if minutes <= 30 {
                return .orange
            } else {
                return .red
            }
        }
        return .gray
    }
    
    // MARK: - Methods
    
    private func formatHours(_ hours: OperatingHours) -> String {
        // Simple format for now - could be enhanced to show specific days
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        if let todayHours = hours.hours(for: weekday) {
            if todayHours.isClosed {
                return "Closed today"
            }
            return "\(todayHours.open) - \(todayHours.close)"
        }
        return "Hours vary"
    }
    
    private func calculateDistance() {
        guard let userLocation = locationService.currentLocation else {
            distance = "Unknown"
            return
        }
        
        let facilityLocation = CLLocation(
            latitude: facility.coordinate.latitude,
            longitude: facility.coordinate.longitude
        )
        
        let distanceMeters = userLocation.distance(from: facilityLocation)
        let distanceMiles = distanceMeters / 1609.34
        
        distance = String(format: "%.1f mi", distanceMiles)
    }
    
    private func fetchDrivingTime() {
        guard let userLocation = locationService.currentLocation else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(
            coordinate: userLocation.coordinate
        ))
        request.destination = MKMapItem(placemark: MKPlacemark(
            coordinate: facility.coordinate
        ))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else { return }
            
            let minutes = Int(route.expectedTravelTime / 60)
            DispatchQueue.main.async {
                self.drivingTime = "\(minutes) min"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FacilityDetailSheet(
        facility: Facility(
            id: "1",
            name: "Barnes-Jewish Hospital",
            address: "1 Barnes Jewish Hospital Plaza",
            city: "St. Louis",
            state: "MO",
            zipCode: "63110",
            phone: "(314) 747-3000",
            facilityType: .emergencyDepartment,
            coordinate: CLLocationCoordinate2D(latitude: 38.6362, longitude: -90.2644),
            cmsAverageWaitMinutes: 45,
            apiEndpoint: nil,
            websiteURL: nil,
            operatingHours: nil
        ),
        waitTime: "45 min",
        onNavigate: {},
        onDismiss: {}
    )
}
