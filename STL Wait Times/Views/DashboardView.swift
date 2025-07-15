import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = FacilityListViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            NavigationView {
                VStack(spacing: 0) {
                    // Main content - matches desired UI exactly
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Main page title
                            Text("Nearby Facilities")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 20)
                            
                            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                                // Emergency Departments Section
                                facilitySection(
                                    title: "Emergency Departments", 
                                    facilities: emergencyDepartments
                                )
                                
                                // Urgent Care Section  
                                facilitySection(
                                    title: "Urgent Cares",
                                    facilities: urgentCareFacilities
                                )
                            }
                        }
                    }
                    .refreshable {
                        viewModel.refreshWaitTimes()
                    }
                }
                .navigationTitle("STL WaitLine")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            // Hamburger menu
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.primary)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            Button {
                                // Add facility
                            } label: {
                                Image(systemName: "plus")
                                    .foregroundColor(.primary)
                            }
                            Button {
                                // More options
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            
            // Bottom Tab Navigation
            CustomTabView(selectedTab: $selectedTab)
        }
    }
    
    // MARK: - Facility Section
    private func facilitySection(title: String, facilities: [MockFacility]) -> some View {
        Section {
            ForEach(facilities) { facility in
                NavigationLink(destination: EmptyView()) {
                    WatchlistRow(facility: facility)
                        .padding(.horizontal, 16)
                }
                .buttonStyle(PlainButtonStyle())
                
                if facility.id != facilities.last?.id {
                    Divider()
                        .padding(.leading, 82)
                }
            }
        } header: {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Mock Data
    private var emergencyDepartments: [MockFacility] {
        [
            MockFacility(id: "1", iconText: "plus", iconColor: .red, name: "Mercy Hospital", subtitle: "2.1 miles away", value: "3h 45m", change: "+15 min", changeColor: .green),
            MockFacility(id: "2", iconText: "plus", iconColor: .blue, name: "St. Luke's Hospital", subtitle: "4.5 miles away", value: "4h 15m", change: "+5 min", changeColor: .green),
            MockFacility(id: "3", iconText: "plus", iconColor: .blue, name: "Barnes-Jewish Hospital", subtitle: "6.2 miles away", value: "5h 30m", change: "-20 min", changeColor: .red)
        ]
    }
    
    private var urgentCareFacilities: [MockFacility] {
        [
            MockFacility(id: "4", iconText: "bandage", iconColor: .green, name: "Total Access Urgent Care", subtitle: "1.8 miles away", value: "45m", change: "+5 min", changeColor: .green),
            MockFacility(id: "5", iconText: "bandage", iconColor: .red, name: "Concentra Urgent Care", subtitle: "3.2 miles away", value: "1h 10m", change: "-10 min", changeColor: .red),
            MockFacility(id: "6", iconText: "bandage", iconColor: Color(red: 0.2, green: 0.2, blue: 0.2), name: "Ortho Urgent Care", subtitle: "5.1 miles away", value: "25m", change: "+2 min", changeColor: .green)
        ]
    }
}

// MARK: - Mock Data Model
struct MockFacility: Identifiable {
    let id: String
    let iconText: String
    let iconColor: Color
    let name: String
    let subtitle: String
    let value: String
    let change: String
    let changeColor: Color
}

// MARK: - Watchlist Row (Exact Match to Desired UI)
struct WatchlistRow: View {
    let facility: MockFacility
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon (medical icons)
            ZStack {
                Circle()
                    .fill(facility.iconColor)
                    .frame(width: 50, height: 50)
                
                Image(systemName: facility.iconText)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(facility.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(facility.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Value and change (matches desired layout exactly)
            VStack(alignment: .trailing, spacing: 2) {
                Text(facility.value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(facility.change)
                    .font(.subheadline)
                    .foregroundColor(facility.changeColor)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Dashboard Facility Row
struct DashboardFacilityRow: View {
    let facility: Facility
    @ObservedObject var viewModel: FacilityListViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Facility Icon
            facilityIcon
            
            // Center: Facility Info
            VStack(alignment: .leading, spacing: 4) {
                Text(facilityNameDisplay)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(facilitySubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Right: Wait Time & Distance
            VStack(alignment: .trailing, spacing: 2) {
                Text(waitTimeDisplay)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Text(distanceDisplay)
                        .font(.subheadline)
                        .foregroundColor(waitTimeChangeColor)
                        .fontWeight(.medium)
                    
                    if !waitTimeChangeText.isEmpty {
                        Text(waitTimeChangeText)
                            .font(.subheadline)
                            .foregroundColor(waitTimeChangeColor)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var facilityIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 50, height: 50)
            
            Text(iconText)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private var facilityNameDisplay: String {
        let words = facility.name.split(separator: " ")
        if words.count > 3 {
            return words.prefix(3).joined(separator: " ")
        }
        return facility.name
    }
    
    private var facilitySubtitle: String {
        return facility.facilityType.displayName
    }
    
    private var waitTimeDisplay: String {
        guard let waitTime = viewModel.waitTime(for: facility) else {
            if let cmsWait = facility.cmsAverageWaitMinutes {
                return "\(cmsWait) min"
            }
            return "No data"
        }
        
        return waitTime.displayText
    }
    
    private var distanceDisplay: String {
        return viewModel.formattedDistance(to: facility) ?? "Unknown"
    }
    
    private var waitTimeChangeText: String {
        // For now, show wait time trend indicator
        if let waitTime = viewModel.waitTime(for: facility) {
            return waitTime.isStale ? "stale" : "live"
        }
        return "avg"
    }
    
    private var waitTimeChangeColor: Color {
        guard let waitTime = viewModel.waitTime(for: facility) else {
            return .secondary
        }
        
        // Color coding based on wait time length
        if waitTime.waitMinutes <= 15 {
            return .green
        } else if waitTime.waitMinutes <= 45 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var iconBackgroundColor: Color {
        switch facility.facilityType {
        case .emergencyDepartment:
            return Color.red
        case .urgentCare:
            // Vary colors by facility ID for visual variety like the original
            let hash = abs(facility.id.hashValue)
            let colors: [Color] = [.blue, .green, .purple, .orange, .cyan, .mint]
            return colors[hash % colors.count]
        }
    }
    
    private var iconText: String {
        switch facility.facilityType {
        case .emergencyDepartment:
            return "ED"
        case .urgentCare:
            return "UC"
        }
    }
}

// MARK: - Custom Tab View
struct CustomTabView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            TabButton(title: "Watchlist", iconName: "star.fill", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            TabButton(title: "Chart", iconName: "chart.bar.fill", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            TabButton(title: "Explore", iconName: "safari.fill", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            TabButton(title: "Ideas", iconName: "lightbulb.fill", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
            TabButton(title: "Menu", iconName: "line.3.horizontal", isSelected: selectedTab == 4) {
                selectedTab = 4
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.systemGray4)),
            alignment: .top
        )
    }
}

struct TabButton: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .blue : .gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}