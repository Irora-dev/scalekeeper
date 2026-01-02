import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - Enclosure View

struct EnclosureView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = EnclosureViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingAddEnclosure = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.primaryAccent))
                } else if viewModel.enclosures.isEmpty {
                    emptyState
                } else {
                    enclosureList
                }
            }
            .navigationTitle("Enclosures")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddEnclosure = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(themeManager.currentTheme.primaryAccent)
                    }
                }
            }
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
            .sheet(isPresented: $showingAddEnclosure) {
                AddEnclosureView { newEnclosure in
                    Task {
                        await viewModel.load()
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: ScaleSpacing.lg) {
            Image(systemName: "square.3.layers.3d")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.primaryAccent.opacity(0.5))
                .shadow(color: themeManager.currentTheme.primaryAccent.opacity(0.3), radius: 10)

            Text("No Enclosures Yet")
                .font(.scaleTitle2)
                .foregroundColor(.scaleTextPrimary)

            Text("Add enclosures to track cleaning schedules, environment readings, and maintenance.")
                .font(.scaleSubheadline)
                .foregroundColor(.scaleTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ScaleSpacing.xxl)

            ScalePrimaryButton("Add Enclosure", icon: "plus") {
                showingAddEnclosure = true
            }
            .padding(.horizontal, ScaleSpacing.xxl)
        }
    }

    // MARK: - Enclosure List

    private var enclosureList: some View {
        ScrollView {
            VStack(spacing: ScaleSpacing.lg) {
                // Cleaning Alerts Section
                if !viewModel.cleaningAlerts.isEmpty {
                    cleaningAlertsSection
                }

                // Enclosures Grid
                LazyVStack(spacing: ScaleSpacing.md) {
                    ForEach(viewModel.enclosures, id: \.id) { enclosure in
                        NavigationLink {
                            EnclosureDetailView(enclosure: enclosure)
                        } label: {
                            EnclosureCard(
                                enclosure: enclosure,
                                cleaningStatus: viewModel.cleaningStatus(for: enclosure)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(ScaleSpacing.lg)
        }
    }

    // MARK: - Cleaning Alerts Section

    private var cleaningAlertsSection: some View {
        ScaleCard(
            header: .init(
                title: "Cleaning Alerts",
                subtitle: "\(viewModel.cleaningAlerts.count) tasks",
                icon: "exclamationmark.triangle.fill",
                iconColor: .scaleWarning
            )
        ) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(viewModel.cleaningAlerts, id: \.enclosureName) { status in
                    CleaningAlertRow(status: status) {
                        // Navigate to enclosure or log cleaning
                    }
                }
            }
        }
    }
}

// MARK: - Enclosure Card

struct EnclosureCard: View {
    let enclosure: Enclosure
    let cleaningStatus: [CleaningStatus]

    private var hasOverdue: Bool {
        cleaningStatus.contains { $0.urgency == .overdue }
    }

    private var hasDueSoon: Bool {
        cleaningStatus.contains { $0.urgency == .dueSoon }
    }

    var body: some View {
        ScaleCard {
            VStack(alignment: .leading, spacing: ScaleSpacing.md) {
                // Header
                HStack {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(ThemeManager.shared.currentTheme.primaryAccent.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: enclosure.enclosureType.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(enclosure.name)
                            .font(.scaleHeadline)
                            .foregroundColor(.scaleTextPrimary)

                        Text(enclosure.enclosureType.displayName)
                            .font(.scaleCaption)
                            .foregroundColor(.scaleTextSecondary)
                    }

                    Spacer()

                    // Status indicator
                    if hasOverdue {
                        statusBadge(text: "Overdue", color: .scaleError)
                    } else if hasDueSoon {
                        statusBadge(text: "Due Soon", color: .nebulaGold)
                    } else {
                        statusBadge(text: "On Track", color: .nebulaCyan)
                    }
                }

                // Info Row
                HStack(spacing: ScaleSpacing.lg) {
                    if let dimensions = formattedDimensions {
                        infoItem(icon: "ruler", text: dimensions)
                    }

                    if let substrate = enclosure.substrateType {
                        infoItem(icon: "square.3.layers.3d.down.left", text: substrate.displayName)
                    }

                    if enclosure.isBioactive {
                        infoItem(icon: "leaf.fill", text: "Bioactive", color: .nebulaCyan)
                    }
                }

                // Environment Targets
                if enclosure.targetTempHotF != nil || enclosure.targetHumidity != nil {
                    HStack(spacing: ScaleSpacing.lg) {
                        if let hotTemp = enclosure.targetTempHotF, let coolTemp = enclosure.targetTempCoolF {
                            environmentItem(
                                icon: "thermometer",
                                text: "\(Int(coolTemp))-\(Int(hotTemp))°F"
                            )
                        }

                        if let humidity = enclosure.targetHumidity {
                            environmentItem(
                                icon: "humidity",
                                text: "\(humidity)%"
                            )
                        }
                    }
                }

                // Cleaning Summary
                if !cleaningStatus.isEmpty {
                    Divider()
                        .background(Color.scaleBorder)

                    HStack(spacing: ScaleSpacing.md) {
                        ForEach(cleaningStatus.prefix(3), id: \.cleaningType) { status in
                            cleaningStatusChip(status)
                        }

                        if cleaningStatus.count > 3 {
                            Text("+\(cleaningStatus.count - 3)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.scaleTextTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.scaleTextTertiary)
                    }
                }
            }
        }
    }

    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.15))
            )
    }

    private func infoItem(icon: String, text: String, color: Color = .scaleTextSecondary) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 12))
        }
        .foregroundColor(color)
    }

    private func environmentItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent)
    }

    private func cleaningStatusChip(_ status: CleaningStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(urgencyColor(status.urgency))
                .frame(width: 6, height: 6)

            Text(status.cleaningType.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.scaleTextSecondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.cosmicDeep)
        )
    }

    private func urgencyColor(_ urgency: CleaningUrgency) -> Color {
        switch urgency {
        case .onTrack: return .nebulaCyan
        case .dueSoon: return .nebulaGold
        case .overdue: return .scaleError
        }
    }

    private var formattedDimensions: String? {
        guard let l = enclosure.lengthInches,
              let w = enclosure.widthInches,
              let h = enclosure.heightInches else { return nil }
        return "\(Int(l))×\(Int(w))×\(Int(h))\""
    }
}

// MARK: - Cleaning Alert Row

struct CleaningAlertRow: View {
    let status: CleaningStatus
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                // Icon
                ZStack {
                    Circle()
                        .fill(urgencyColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: status.cleaningType.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(urgencyColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(status.cleaningType.displayName)
                        .font(.scaleSubheadline)
                        .foregroundColor(.scaleTextPrimary)

                    Text(status.enclosureName)
                        .font(.scaleCaption)
                        .foregroundColor(.scaleTextSecondary)
                }

                Spacer()

                // Days indicator
                VStack(alignment: .trailing, spacing: 2) {
                    if status.urgency == .overdue {
                        Text("\(abs(status.daysUntilDue))d overdue")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.scaleError)
                    } else {
                        Text("Due in \(status.daysUntilDue)d")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.nebulaGold)
                    }
                }
            }
            .padding(.vertical, ScaleSpacing.xs)
        }
    }

    private var urgencyColor: Color {
        switch status.urgency {
        case .onTrack: return .nebulaCyan
        case .dueSoon: return .nebulaGold
        case .overdue: return .scaleError
        }
    }
}

// MARK: - Enclosure View Model

@MainActor
@Observable
final class EnclosureViewModel: ObservableObject {
    // MARK: - Dependencies
    private let dataService: DataService
    private let cleaningService: CleaningService

    // MARK: - State
    var enclosures: [Enclosure] = []
    var cleaningAlerts: [CleaningStatus] = []
    private var statusCache: [UUID: [CleaningStatus]] = [:]
    var isLoading = false
    var error: Error?

    // MARK: - Init
    init(
        dataService: DataService = .shared,
        cleaningService: CleaningService = .shared
    ) {
        self.dataService = dataService
        self.cleaningService = cleaningService
    }

    // MARK: - Load
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            enclosures = try dataService.fetchEnclosures()

            // Load cleaning status for each enclosure
            var alerts: [CleaningStatus] = []
            for enclosure in enclosures {
                let statuses = try cleaningService.cleaningStatus(for: enclosure)
                statusCache[enclosure.id] = statuses

                // Collect alerts (overdue or due soon)
                alerts.append(contentsOf: statuses.filter { $0.urgency != .onTrack })
            }

            cleaningAlerts = alerts.sorted { $0.daysUntilDue < $1.daysUntilDue }
        } catch {
            self.error = error
        }
    }

    // MARK: - Get Status
    func cleaningStatus(for enclosure: Enclosure) -> [CleaningStatus] {
        return statusCache[enclosure.id] ?? []
    }
}

// MARK: - Preview

#Preview {
    EnclosureView()
        .environmentObject(AppState())
}
