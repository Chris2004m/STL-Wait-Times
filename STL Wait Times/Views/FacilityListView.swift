import SwiftUI

/// Main facility list view showing EDs and Urgent Care centers
struct FacilityListView: View {
    @StateObject private var viewModel = FacilityListViewModel()
    @State private var showingSortOptions = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Safety disclaimer banner
                safetyBanner
                
                // Controls section
                controlsSection
                
                // Facility list
                facilityList
            }
            .navigationTitle("STL WaitLine")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sort") {
                        showingSortOptions = true
                    }
                }
            }
            .alert("Location Permission", isPresented: $viewModel.showLocationPermissionAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Location access is needed to show distances and enable wait time logging. Please enable location access in Settings.")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .confirmationDialog("Sort Options", isPresented: $showingSortOptions) {
                ForEach(FacilityListViewModel.SortOption.allCases, id: \.self) { option in
                    Button(option.displayName) {
                        viewModel.setSortOption(option)
                    }
                }
            }
            .onAppear {
                // Ensure driving time calculations are triggered when view appears
                viewModel.onViewAppear()
            }
        }
    }
    
    // MARK: - Safety Banner
    private var safetyBanner: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Times are estimates. If you think you're having an emergency, call 911.")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemYellow).opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemYellow))
                .opacity(0.3),
            alignment: .bottom
        )
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        VStack(spacing: 12) {
            // Facility type toggle
            Picker("Facility Type", selection: $viewModel.selectedFacilityType) {
                ForEach(Facility.FacilityType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: viewModel.selectedFacilityType) { _, _ in
                viewModel.applyFilter()
            }
            
            
            // Sort indicator
            HStack {
                Text("Sorted by: \(viewModel.sortOption.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8 as CGFloat)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Facility List
    private var facilityList: some View {
        List(viewModel.facilities) { facility in
            NavigationLink(destination: FacilityDetailView(facility: facility)) {
                FacilityRowView(facility: facility, viewModel: viewModel)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            viewModel.refreshWaitTimes()
        }
    }
}

// MARK: - Facility Row View
struct FacilityRowView: View {
    let facility: Facility
    @ObservedObject var viewModel: FacilityListViewModel
    @ObservedObject private var locationService = LocationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(facility.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    // Distance and driving time info
                    HStack(spacing: 4) {
                        if let distance = viewModel.formattedDistance(to: facility) {
                            Text(distance)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Always show driving time section if we have location
                        if locationService.currentLocation != nil {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Distance only (driving time feature removed)
                        }
                    }
                }
                
                Spacer()
                
                // Wait time indicators
                waitTimeIndicators
            }
            
            // Address
            Text(facility.fullAddress)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
    
    private var waitTimeIndicators: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Show loading indicator if refreshing, otherwise show wait time
            if viewModel.isRefreshing(facility) {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(x: 0.8, y: 0.8)
                    Text("Refreshing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else {
                // Primary wait time
                waitTimeChip(
                    text: viewModel.waitTimeDisplayString(for: facility),
                    source: viewModel.waitTimeSourceString(for: facility),
                    isStale: viewModel.waitTime(for: facility)?.isStale ?? false
                )
            }
            
            // CMS average for EDs
            if facility.facilityType == .emergencyDepartment,
               let cmsWait = facility.cmsAverageWaitMinutes {
                waitTimeChip(
                    text: "\(cmsWait) min",
                    source: "CMS Avg",
                    isStale: false,
                    isSecondary: true
                )
            }
        }
    }
    
    private func waitTimeChip(text: String, source: String, isStale: Bool, isSecondary: Bool = false) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Text(text)
                    .font(isSecondary ? .caption2 : .caption)
                    .fontWeight(isSecondary ? .regular : .semibold)
                
                if isStale {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            if !source.isEmpty {
                Text(source)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSecondary ? Color(.systemGray6) : Color(.systemBlue).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSecondary ? Color(.systemGray4) : Color(.systemBlue).opacity(0.3), lineWidth: 1)
        )
    }
}



// MARK: - Preview
struct FacilityListView_Previews: PreviewProvider {
    static var previews: some View {
        FacilityListView()
    }
} 