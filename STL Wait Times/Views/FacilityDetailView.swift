import SwiftUI
import Charts
import MapKit
import CoreLocation

/// Detailed view for a specific facility with charts and actions
struct FacilityDetailView: View {
    let facility: Facility
    @StateObject private var viewModel = FacilityDetailViewModel()
    @State private var showingWaitTimeLogger = false
    @State private var showingCallConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header section
                headerSection
                
                // Current wait time
                currentWaitTimeSection
                
                // Wait time chart
                waitTimeChartSection
                
                // Actions section
                actionsSection
                
                // Wait time logging
                waitTimeLoggingSection
                
                // Facility details
                facilityDetailsSection
            }
            .padding()
        }
        .navigationTitle(facility.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadData(for: facility)
        }
        .sheet(isPresented: $showingWaitTimeLogger) {
            WaitTimeLoggerView(facility: facility)
        }
        .confirmationDialog("Call \(facility.name)?", isPresented: $showingCallConfirmation) {
            Button("Call") {
                makePhoneCall()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will open the Phone app to call \(facility.name)")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(facility.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    
                    Text(facility.facilityType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemBlue).opacity(0.1))
                        )
                }
                
                Spacer()
                
                if let distance = viewModel.distanceToFacility {
                    Text(LocationService.shared.formatDistance(distance))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(facility.fullAddress)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Current Wait Time Section
    private var currentWaitTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Wait Time")
                .font(.headline)
            
            if let waitTime = viewModel.currentWaitTime {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(waitTime.displayText)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(waitTime.isStale ? .orange : .primary)
                        
                        HStack {
                            Text("Real-time data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if waitTime.isStale {
                                Image(systemName: "clock.badge.exclamationmark")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if waitTime.patientsInLine > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(waitTime.patientsInLine)")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("in line")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            } else {
                Text("No wait time data available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
            }
            
            // CMS average for EDs
            if facility.facilityType == .emergencyDepartment,
               let cmsWait = facility.cmsAverageWaitMinutes {
                HStack {
                    Text("CMS Average:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(cmsWait) min")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Wait Time Chart Section
    private var waitTimeChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("24-Hour Trend")
                .font(.headline)
            
            if viewModel.chartDataPoints.isEmpty {
                Text("No historical data available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
            } else {
                Chart(viewModel.chartDataPoints) { dataPoint in
                    LineMark(
                        x: .value("Time", dataPoint.timestamp),
                        y: .value("Wait Time", dataPoint.waitMinutes)
                    )
                    .foregroundStyle(colorForSource(dataPoint.source))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let minutes = value.as(Int.self) {
                                Text("\(minutes)m")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date, format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                // Directions button
                Button(action: openDirections) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Directions")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Call button
                Button(action: { showingCallConfirmation = true }) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Call")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Wait Time Logging Section
    private var waitTimeLoggingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Help Others")
                .font(.headline)
            
            if viewModel.canLogWaitTime {
                Button(action: { showingWaitTimeLogger = true }) {
                    HStack {
                        Image(systemName: "clock.badge.plus")
                        Text("Log My Wait Time")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else {
                Text("Move closer to the facility to log your wait time")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
            }
        }
    }
    
    // MARK: - Facility Details Section
    private var facilityDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRowView(label: "Type", value: facility.facilityType.displayName)
                DetailRowView(label: "Address", value: facility.fullAddress)
                DetailRowView(label: "Phone", value: facility.phone)
                DetailRowView(label: "City", value: "\(facility.city), \(facility.state)")
                DetailRowView(label: "ZIP", value: facility.zipCode)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func colorForSource(_ source: WaitTime.WaitTimeSource) -> Color {
        switch source {
        case .api:
            return .blue
        case .crowdSourced:
            return .green
        case .cmsAverage:
            return .orange
        }
    }
    
    private func openDirections() {
        let placemark = MKPlacemark(coordinate: facility.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = facility.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    private func makePhoneCall() {
        guard let url = URL(string: "tel://\(facility.phone)") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Detail Row View
struct DetailRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.body)
        }
    }
}

// MARK: - Facility Detail ViewModel
class FacilityDetailViewModel: ObservableObject {
    @Published var currentWaitTime: WaitTime?
    @Published var chartDataPoints: [WaitTimeDataPoint] = []
    @Published var distanceToFacility: CLLocationDistance?
    @Published var canLogWaitTime = false
    
    private let locationService = LocationService.shared
    private let waitTimeService = WaitTimeService.shared
    
    func loadData(for facility: Facility) {
        // Load current wait time
        currentWaitTime = waitTimeService.getBestWaitTime(for: facility)
        
        // Calculate distance
        distanceToFacility = locationService.distance(to: facility)
        
        // Check if user can log wait time
        canLogWaitTime = locationService.canLogWaitTime(for: facility.id)
        
        // Start geo-fencing
        locationService.startGeoFencing(for: facility)
        
        // Generate sample chart data (in real app, this would come from historical data)
        generateSampleChartData(for: facility)
    }
    
    private func generateSampleChartData(for facility: Facility) {
        // Generate 24 hours of sample data points
        let now = Date()
        let calendar = Calendar.current
        
        chartDataPoints = (0..<24).compactMap { hourOffset in
            guard let timestamp = calendar.date(byAdding: .hour, value: -hourOffset, to: now) else { return nil }
            
            // Generate realistic wait time based on facility type and time of day
            let hour = calendar.component(.hour, from: timestamp)
            let baseWait = facility.facilityType == .emergencyDepartment ? 120 : 20
            let timeMultiplier = getTimeMultiplier(for: hour)
            let waitMinutes = Int(Double(baseWait) * timeMultiplier)
            
            return WaitTimeDataPoint(
                timestamp: timestamp,
                waitMinutes: waitMinutes,
                source: .api
            )
        }.reversed()
    }
    
    private func getTimeMultiplier(for hour: Int) -> Double {
        // Simulate typical wait time patterns
        switch hour {
        case 0...6: return 0.5  // Late night/early morning
        case 7...9: return 0.8  // Morning
        case 10...16: return 1.0 // Day
        case 17...20: return 1.4 // Evening rush
        case 21...23: return 1.1 // Night
        default: return 1.0
        }
    }
}

// MARK: - Wait Time Logger View
struct WaitTimeLoggerView: View {
    let facility: Facility
    @State private var checkInTime = Date()
    @State private var seenTime: Date?
    @State private var estimatedWaitMinutes: Int?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Log Your Wait Time")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Help other patients by sharing your wait time experience at \(facility.name)")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Check-in Time")
                        .font(.headline)
                    
                    DatePicker("Check-in Time", selection: $checkInTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(WheelDatePickerStyle())
                }
                
                if let seenTime = seenTime {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Total Wait Time")
                            .font(.headline)
                        
                        let waitMinutes = Int(seenTime.timeIntervalSince(checkInTime) / 60)
                        Text("\(waitMinutes) minutes")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                Button(seenTime == nil ? "Mark as Seen" : "Update") {
                    seenTime = Date()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
                if seenTime != nil {
                    Button("Submit") {
                        submitWaitTime()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Wait Time Logger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitWaitTime() {
        // In a real app, this would submit to a backend service
        // For now, we'll just dismiss
        dismiss()
    }
}

// MARK: - Preview
struct FacilityDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FacilityDetailView(facility: FacilityData.allFacilities[0])
        }
    }
} 