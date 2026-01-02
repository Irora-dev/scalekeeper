import SwiftUI
import ScaleUI

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem {
                    Label(Tab.dashboard.title, systemImage: appState.selectedTab == .dashboard ? Tab.dashboard.selectedIcon : Tab.dashboard.icon)
                }
                .tag(Tab.dashboard)

            CollectionView()
                .tabItem {
                    Label(Tab.collection.title, systemImage: appState.selectedTab == .collection ? Tab.collection.selectedIcon : Tab.collection.icon)
                }
                .tag(Tab.collection)

            // Hub tab - empty view, triggers sheet
            Color.clear
                .tabItem {
                    Label(Tab.hub.title, systemImage: Tab.hub.selectedIcon)
                }
                .tag(Tab.hub)

            CareView()
                .tabItem {
                    Label(Tab.care.title, systemImage: appState.selectedTab == .care ? Tab.care.selectedIcon : Tab.care.icon)
                }
                .tag(Tab.care)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: appState.selectedTab == .settings ? Tab.settings.selectedIcon : Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(themeManager.currentTheme.primaryAccent)
        .onChange(of: appState.selectedTab) { oldValue, newValue in
            if newValue == .hub {
                // Show hub sheet and return to previous tab
                appState.isShowingQuickActionsHub = true
                appState.selectedTab = oldValue
            } else {
                appState.previousTab = newValue
            }
        }
        .sheet(item: $appState.activeSheet) { sheet in
            sheetContent(for: sheet)
        }
        .sheet(isPresented: $appState.isShowingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $appState.isShowingQuickActionsHub) {
            QuickActionsHubView()
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: SheetType) -> some View {
        switch sheet {
        case .addAnimal:
            AddAnimalView()
        case .editAnimal(let id):
            EditAnimalView(animalID: id)
        case .logFeeding(let id):
            LogFeedingView(animalID: id)
        case .quickFeed(let id):
            QuickFeedView(animalID: id)
        case .batchFeed:
            BatchFeedingView()
        case .addWeight(let id):
            AddWeightView(animalID: id)
        case .addLength(let id):
            AddLengthView(animalID: id)
        case .addHealthNote(let id):
            AddHealthNoteView(animalID: id)
        case .addShed(let id):
            AddShedView(animalID: id)
        case .quickNote:
            QuickNoteView()
        case .quickNoteForAnimal(let id):
            QuickNoteView(animalID: id)
        case .newPairing:
            NewPairingView()
        case .editPairing(let id):
            EditPairingView(pairingID: id)
        case .addClutch(let id):
            AddClutchView(pairingID: id)
        case .settings:
            SettingsView()
        case .markRegurgitation(let id):
            MarkRegurgitationView(feedingID: id)
        }
    }
}

// MARK: - Placeholder Views (to be implemented)

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                VStack(spacing: ScaleSpacing.xl) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.nebulaGold)
                        .shadow(color: .nebulaGold.opacity(0.4), radius: 10)

                    Text("Upgrade to Premium")
                        .font(.scaleTitle)
                        .foregroundColor(.scaleTextPrimary)

                    Text("Unlock unlimited animals, genetics calculator, breeding tools, and more.")
                        .font(.scaleBody)
                        .foregroundColor(.scaleTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ScaleSpacing.xxl)

                    Spacer()

                    ScalePrimaryButton("View Plans") {
                        // Show subscription options
                    }
                    .padding(.horizontal, ScaleSpacing.xxl)
                }
                .padding(.top, ScaleSpacing.xxxl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.scaleTextSecondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .environmentObject(AppState())
}
