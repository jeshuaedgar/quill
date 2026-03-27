import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1 — Welcome
            OnboardingPage(
                icon: "pencil.and.outline",
                iconColor: .purple,
                title: "Welcome to Quill",
                subtitle: "A supercharged reminders app that helps you remember everything, effortlessly.",
                page: 0,
                currentPage: $currentPage
            )
            .tag(0)
            
            // Page 2 — Smart Input
            OnboardingPage(
                icon: "sparkles",
                iconColor: .purple,
                title: "Smart Input",
                subtitle: "Just type naturally — \"Call dentist next Thursday at 3pm\" — and Quill understands dates, priorities, and categories automatically.",
                page: 1,
                currentPage: $currentPage
            )
            .tag(1)
            
            // Page 3 — AI Powered
            OnboardingPage(
                icon: "brain",
                iconColor: .pink,
                title: "AI Powered",
                subtitle: "Get daily briefings, smart categorization, and priority suggestions — all processed on-device. Your data never leaves your phone.",
                page: 2,
                currentPage: $currentPage
            )
            .tag(2)
            
            // Page 4 — Privacy
            OnboardingPage(
                icon: "lock.shield.fill",
                iconColor: .green,
                title: "Private by Design",
                subtitle: "No accounts, no tracking, no servers. Everything stays on your device and in your iCloud.",
                page: 3,
                currentPage: $currentPage,
                isLastPage: true,
                onGetStarted: {
                    completeOnboarding()
                }
            )
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
    
    private func completeOnboarding() {
        HapticManager.shared.success()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Page

struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let page: Int
    @Binding var currentPage: Int
    var isLastPage: Bool = false
    var onGetStarted: (() -> Void)?
    
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(iconColor)
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)
            
            // Title
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            
            // Subtitle
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                if isLastPage {
                    Button {
                        onGetStarted?()
                    } label: {
                        Text("Get Started")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(iconColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 32)
                    
                    // Request notification permission
                    Button {
                        NotificationManager.shared.requestPermission()
                    } label: {
                        Text("Enable Notifications")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 32)
                } else {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                        HapticManager.shared.selection()
                    } label: {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(iconColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 32)
                    
                    Button {
                        withAnimation {
                            currentPage = 3
                        }
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .onAppear {
            appeared = false
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
        .onChange(of: currentPage) {
            if currentPage == page {
                appeared = false
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                    appeared = true
                }
            }
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
