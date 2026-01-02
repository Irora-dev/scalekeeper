import SwiftUI
import ScaleUI

// MARK: - Theme Onboarding View

struct ThemeOnboardingView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedTheme: AppTheme = .purple
    @State private var animateIn = false

    var body: some View {
        ZStack {
            // Dynamic background based on selection
            backgroundGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: selectedTheme)

            VStack(spacing: ScaleSpacing.xxl) {
                Spacer()

                // Logo/Icon area
                ZStack {
                    Circle()
                        .fill(selectedTheme.primaryAccent.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateIn ? 1 : 0.5)

                    Image(systemName: "lizard.fill")
                        .font(.system(size: 50))
                        .foregroundColor(selectedTheme.primaryAccent)
                        .scaleEffect(animateIn ? 1 : 0.5)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateIn)

                // Title
                VStack(spacing: ScaleSpacing.sm) {
                    Text("Welcome to ScaleKeeper")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Choose your color theme")
                        .font(.scaleBody)
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: animateIn)

                Spacer()

                // Theme Options
                VStack(spacing: ScaleSpacing.lg) {
                    ThemeOptionCard(
                        theme: .green,
                        isSelected: selectedTheme == .green,
                        action: { selectedTheme = .green }
                    )
                    .opacity(animateIn ? 1 : 0)
                    .offset(x: animateIn ? 0 : -50)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: animateIn)

                    ThemeOptionCard(
                        theme: .purple,
                        isSelected: selectedTheme == .purple,
                        action: { selectedTheme = .purple }
                    )
                    .opacity(animateIn ? 1 : 0)
                    .offset(x: animateIn ? 0 : 50)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: animateIn)
                }
                .padding(.horizontal, ScaleSpacing.xl)

                Spacer()

                // Continue Button
                Button {
                    themeManager.setTheme(selectedTheme)
                    themeManager.completeOnboarding()
                    ScaleHaptics.success()
                } label: {
                    HStack {
                        Text("Continue")
                            .font(.scaleButton)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ScaleSpacing.md)
                    .background(
                        Capsule()
                            .fill(selectedTheme.primaryAccent)
                    )
                }
                .padding(.horizontal, ScaleSpacing.xxl)
                .padding(.bottom, ScaleSpacing.xxl)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 30)
                .animation(.easeOut(duration: 0.5).delay(0.6), value: animateIn)

                // Settings note
                Text("You can change this later in Settings")
                    .font(.scaleCaption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, ScaleSpacing.lg)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.7), value: animateIn)
            }
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            stops: [
                .init(color: Color.cosmicBlack, location: 0),
                .init(color: selectedTheme == .purple ? Color.cosmicDeep : Color(red: 0.05, green: 0.12, blue: 0.08), location: 0.5),
                .init(color: Color.cosmicBlack, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Theme Option Card

struct ThemeOptionCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            ScaleHaptics.light()
        }) {
            HStack(spacing: ScaleSpacing.lg) {
                // Color preview
                HStack(spacing: 4) {
                    Circle()
                        .fill(theme.primaryAccent)
                        .frame(width: 24, height: 24)
                    Circle()
                        .fill(theme.secondaryAccent)
                        .frame(width: 24, height: 24)
                    Circle()
                        .fill(theme.tertiaryAccent)
                        .frame(width: 24, height: 24)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.scaleHeadline)
                        .foregroundColor(.white)
                    Text(theme.description)
                        .font(.scaleCaption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? theme.primaryAccent : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(theme.primaryAccent)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(ScaleSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: ScaleRadius.lg)
                    .fill(Color.cardBackground.opacity(isSelected ? 1 : 0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: ScaleRadius.lg)
                            .stroke(isSelected ? theme.primaryAccent : Color.scaleBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    ThemeOnboardingView()
}
