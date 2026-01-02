import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - Breeding View

struct BreedingView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                VStack(spacing: 0) {
                    // Cosmic segment picker
                    HStack(spacing: ScaleSpacing.sm) {
                        ForEach(Array(["Pairings", "Clutches", "Genetics"].enumerated()), id: \.offset) { index, title in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedSegment = index
                                }
                            } label: {
                                Text(title)
                                    .font(.system(size: 14, weight: selectedSegment == index ? .semibold : .medium))
                                    .foregroundColor(selectedSegment == index ? .white : themeManager.currentTheme.primaryAccent.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, ScaleSpacing.sm)
                                    .background(
                                        Group {
                                            if selectedSegment == index {
                                                RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                                    .fill(themeManager.currentTheme.primaryAccent)
                                                    .shadow(color: themeManager.currentTheme.primaryAccent.opacity(0.4), radius: 8)
                                            } else {
                                                RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                                    .fill(Color.clear)
                                            }
                                        }
                                    )
                            }
                        }
                    }
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: ScaleRadius.md)
                            .fill(themeManager.currentTheme.cardBackground.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: ScaleRadius.md)
                                    .stroke(themeManager.currentTheme.primaryAccent.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(ScaleSpacing.lg)

                    // Content
                    switch selectedSegment {
                    case 0:
                        pairingsContent
                    case 1:
                        clutchesContent
                    case 2:
                        geneticsContent
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("Breeding")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        appState.presentSheet(.newPairing)
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(themeManager.currentTheme.primaryAccent)
                    }
                }
            }
        }
    }

    // MARK: - Pairings Content

    private var pairingsContent: some View {
        ScrollView {
            VStack(spacing: ScaleSpacing.lg) {
                // Premium check
                if !appState.subscriptionService.isBreeder {
                    premiumPrompt
                } else {
                    emptyPairingsState
                }
            }
            .padding(ScaleSpacing.lg)
        }
    }

    // MARK: - Clutches Content

    private var clutchesContent: some View {
        ScrollView {
            VStack(spacing: ScaleSpacing.lg) {
                if !appState.subscriptionService.isBreeder {
                    premiumPrompt
                } else {
                    emptyClutchesState
                }
            }
            .padding(ScaleSpacing.lg)
        }
    }

    // MARK: - Genetics Content

    private var geneticsContent: some View {
        ScrollView {
            VStack(spacing: ScaleSpacing.lg) {
                if !appState.subscriptionService.isBreeder {
                    premiumPrompt
                } else {
                    geneticsCalculator
                }
            }
            .padding(ScaleSpacing.lg)
        }
    }

    // MARK: - Premium Prompt

    private var premiumPrompt: some View {
        ScaleCard {
            VStack(spacing: ScaleSpacing.lg) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.nebulaMagenta)
                    .shadow(color: .nebulaMagenta.opacity(0.4), radius: 8)

                Text("Breeding Tools")
                    .font(.scaleTitle2)
                    .foregroundColor(.scaleTextPrimary)

                Text("Upgrade to Breeder or Professional to access pairing management, clutch tracking, and the genetics calculator.")
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextSecondary)
                    .multilineTextAlignment(.center)

                ScalePrimaryButton("Upgrade Now") {
                    appState.isShowingPaywall = true
                }
            }
            .padding(.vertical, ScaleSpacing.lg)
        }
    }

    // MARK: - Empty States

    private var emptyPairingsState: some View {
        VStack(spacing: ScaleSpacing.lg) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.nebulaMagenta.opacity(0.5))
                .shadow(color: .nebulaMagenta.opacity(0.3), radius: 10)

            Text("No Pairings Yet")
                .font(.scaleTitle2)
                .foregroundColor(.scaleTextPrimary)

            Text("Create your first pairing to start tracking breeding projects.")
                .font(.scaleSubheadline)
                .foregroundColor(.scaleTextSecondary)
                .multilineTextAlignment(.center)

            ScalePrimaryButton("New Pairing", icon: "plus") {
                appState.presentSheet(.newPairing)
            }
        }
        .padding(.vertical, ScaleSpacing.xxxl)
    }

    private var emptyClutchesState: some View {
        VStack(spacing: ScaleSpacing.lg) {
            Image(systemName: "oval.fill")
                .font(.system(size: 60))
                .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent.opacity(0.5))
                .shadow(color: ThemeManager.shared.currentTheme.primaryAccent.opacity(0.3), radius: 10)

            Text("No Clutches Yet")
                .font(.scaleTitle2)
                .foregroundColor(.scaleTextPrimary)

            Text("Record clutches from your pairings to track incubation and hatching.")
                .font(.scaleSubheadline)
                .foregroundColor(.scaleTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, ScaleSpacing.xxxl)
    }

    // MARK: - Genetics Calculator

    private var geneticsCalculator: some View {
        ScaleCard(
            header: .init(
                title: "Genetics Calculator",
                subtitle: "Calculate offspring outcomes",
                icon: "function",
                iconColor: .nebulaCyan
            )
        ) {
            VStack(spacing: ScaleSpacing.lg) {
                Text("Select parents to calculate potential offspring outcomes.")
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextSecondary)

                // Placeholder for genetics calculator
                RoundedRectangle(cornerRadius: ScaleRadius.md)
                    .fill(ThemeManager.shared.currentTheme.cardBackground)
                    .frame(height: 200)
                    .overlay(
                        Text("Calculator UI Coming Soon")
                            .font(.scaleCaption)
                            .foregroundColor(.scaleTextTertiary)
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BreedingView()
        .environmentObject(AppState())
}
