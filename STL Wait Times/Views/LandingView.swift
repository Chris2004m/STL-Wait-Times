import SwiftUI
import AuthenticationServices   // for SignInWithAppleButton

// MARK: – Helpers -------------------------------------------------------------

/// Rounded pill background with optional border.
struct PillBackground: View {
    var stroke: Bool = true
    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color(white: 0.85), lineWidth: stroke ? 1 : 0)
            )
    }
}

// MARK: – Main View -----------------------------------------------------------

struct LandingView: View {
    @State private var showMainApp = false
    
    var body: some View {
        if showMainApp {
            DashboardView()
        } else {
            ZStack {
                // 1. Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.91, green: 1.00, blue: 0.95),   // #E7FFF3
                        Color(red: 0.87, green: 0.97, blue: 1.00)    // #DDF7FF
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // 2. Floating corner icons
                ZStack {
                    // Hospital cross icon - top left corner
                    Image("HospitalIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .opacity(0.5)
                        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                        .offset(x: -150, y: -350)
                    
                    // Clock icon - top right corner (slightly below hospital icon)
                    Image("ClockIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .opacity(0.5)
                        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                        .offset(x: 150, y: -340)
                }
                
                // 3. Content
                VStack(spacing: 28) {
                    Spacer(minLength: 48)
                    
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("WaitLine")
                        .font(.system(size: 28, weight: .semibold))
                    
                    Text("Know before you go")
                        .font(.system(size: 34, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Text("Live ER & urgent care waits in St. Louis.")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer(minLength: 24)
                    
                    // ---------- Buttons ----------
                    VStack(spacing: 20) {
                        // Apple
                        SignInWithAppleButton(.signIn) { _ in
                            // handle result
                        } onCompletion: { _ in }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        
                        // Google
                        Button {
                            showMainApp = true
                        } label: {
                            HStack(spacing: 12) {
                                Image("GoogleIcon")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("Continue with Google")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 56)
                        }
                        .buttonStyle(.plain)
                        .background(PillBackground(stroke: false))
                        
                        // Email
                        Button {
                            showMainApp = true
                        } label: {
                            Text("Continue with Email")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, minHeight: 56)
                        }
                        .buttonStyle(.plain)
                        .background(PillBackground(stroke: false))
                    }
                    .padding(.horizontal, 24)
                    
                    // Guest link
                    Button("Continue as guest") {
                        showMainApp = true
                    }
                    .buttonStyle(.plain)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .padding(.top, 12)
                    
                    Spacer(minLength: 16)
                    
                    Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 12)
                }
            }
        }
    }
}

#Preview {
    LandingView()
} 