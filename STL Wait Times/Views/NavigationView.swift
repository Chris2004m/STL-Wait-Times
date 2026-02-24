//
//  NavigationView.swift
//  STL Wait Times
//
//  Turn-by-turn navigation UI with Apple Maps
//

import SwiftUI
import MapKit
import AVFoundation

/// Full-screen turn-by-turn navigation view
struct TurnByTurnNavigationView: View {
    let destination: CLLocationCoordinate2D
    let destinationName: String
    let onExit: () -> Void
    
    @StateObject private var navigationService = AppleNavigationService.shared
    @StateObject private var locationService = LocationService.shared
    @State private var selectedRoute: MKRoute?
    @State private var isLoadingRoute = true
    @State private var showExitConfirmation = false
    @State private var voiceGuidance: AVSpeechSynthesizer?
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        ZStack {
            // Map with route
            if let route = selectedRoute {
                Map(position: $cameraPosition) {
                    // Route polyline
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 8)
                    
                    // User location
                    UserAnnotation()
                    
                    // Destination marker
                    Marker(destinationName, coordinate: destination)
                        .tint(.red)
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .ignoresSafeArea()
            } else {
                // Loading state
                ZStack {
                    Color(.systemBackground)
                    ProgressView("Calculating route...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
            
            // Navigation UI Overlay
            VStack(spacing: 0) {
                // Top instruction card
                if navigationService.isNavigating {
                    instructionCard
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // Bottom info bar
                bottomInfoBar
            }
            .animation(.spring(response: 0.3), value: navigationService.isNavigating)
        }
        .onAppear {
            setupNavigation()
            voiceGuidance = AVSpeechSynthesizer()
        }
        .onChange(of: navigationService.currentStep) { _, newStep in
            if let step = newStep {
                speakInstruction(step.instructions)
            }
        }
    }
    
    // MARK: - Instruction Card
    
    private var instructionCard: some View {
        VStack(spacing: 0) {
            // Main instruction
            HStack(spacing: 16) {
                // Direction icon
                Image(systemName: navigationService.currentStep?.directionIcon ?? "arrow.up")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.blue)
                    .clipShape(Circle())
                
                // Instruction text
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDistance(navigationService.distanceToNextStep))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text(navigationService.currentStep?.instructions ?? "Continue")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color(.systemBackground))
            
            // Next step preview (if available)
            if let nextStep = getNextStep() {
                Divider()
                HStack(spacing: 12) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    
                    Text("Then: \(nextStep.instructions)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground).opacity(0.95))
            }
        }
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
        .padding(.top, 50)
    }
    
    // MARK: - Bottom Info Bar
    
    private var bottomInfoBar: some View {
        HStack {
            // Exit button
            Button(action: { showExitConfirmation = true }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.red)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // ETA and distance info
            HStack(spacing: 20) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatDistance(navigationService.remainingDistance))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Text("remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatTime(navigationService.remainingTime))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Text("ETA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color(.systemBackground).opacity(0.95))
        .alert("Exit Navigation", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Exit", role: .destructive) {
                navigationService.stopNavigation()
                onExit()
            }
        } message: {
            Text("Are you sure you want to exit navigation?")
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupNavigation() {
        Task {
            do {
                let route = try await navigationService.calculateRoute(to: destination)
                await MainActor.run {
                    selectedRoute = route
                    isLoadingRoute = false
                    navigationService.startNavigation(route: route, destination: destination)
                    
                    // Set camera to follow user
                    if let userLocation = locationService.currentLocation {
                        cameraPosition = .camera(MapCamera(
                            centerCoordinate: userLocation.coordinate,
                            distance: 1000,
                            heading: 0,
                            pitch: 45
                        ))
                    }
                }
            } catch {
                debugLog("❌ Navigation setup failed: \(error)")
                onExit()
            }
        }
    }
    
    private func getNextStep() -> MKRoute.Step? {
        guard let route = selectedRoute,
              navigationService.currentStepIndex < route.steps.count - 1 else {
            return nil
        }
        return route.steps[navigationService.currentStepIndex + 1]
    }
    
    private func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            let miles = meters / 1609.34
            return String(format: "%.1f mi", miles)
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
    
    private func speakInstruction(_ instruction: String) {
        guard let synthesizer = voiceGuidance else { return }
        
        let utterance = AVSpeechUtterance(string: instruction)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        synthesizer.speak(utterance)
    }
}

// MARK: - Preview

#Preview {
    TurnByTurnNavigationView(
        destination: CLLocationCoordinate2D(latitude: 38.6362, longitude: -90.2644),
        destinationName: "Barnes-Jewish Hospital",
        onExit: {}
    )
}
