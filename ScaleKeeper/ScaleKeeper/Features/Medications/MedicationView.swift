import SwiftUI
import ScaleCore
import ScaleUI

// MARK: - Medication View

struct MedicationView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = MedicationViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingNewTreatment = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.primaryAccent))
                } else {
                    ScrollView {
                        VStack(spacing: ScaleSpacing.lg) {
                            // Overdue Doses Alert
                            if !viewModel.overdueDoses.isEmpty {
                                overdueDosesSection
                            }

                            // Doses Due Today
                            if !viewModel.dosesToday.isEmpty {
                                dosesTodaySection
                            }

                            // Active Treatments
                            if !viewModel.activeTreatments.isEmpty {
                                activeTreatmentsSection
                            }

                            // Empty State
                            if viewModel.isEmpty {
                                emptyState
                            }
                        }
                        .padding(ScaleSpacing.lg)
                    }
                }
            }
            .navigationTitle("Medications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewTreatment = true
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
            .sheet(isPresented: $showingNewTreatment) {
                NewTreatmentView {
                    Task { await viewModel.load() }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: ScaleSpacing.lg) {
            Image(systemName: "pills.circle")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.primaryAccent.opacity(0.5))
                .shadow(color: themeManager.currentTheme.primaryAccent.opacity(0.3), radius: 10)

            Text("No Active Treatments")
                .font(.scaleTitle2)
                .foregroundColor(.scaleTextPrimary)

            Text("Start a treatment plan to track medication schedules and doses for your animals.")
                .font(.scaleSubheadline)
                .foregroundColor(.scaleTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ScaleSpacing.xxl)

            ScalePrimaryButton("Start Treatment", icon: "plus") {
                showingNewTreatment = true
            }
            .padding(.horizontal, ScaleSpacing.xxl)
        }
        .padding(.vertical, ScaleSpacing.xxxl)
    }

    // MARK: - Overdue Doses Section

    private var overdueDosesSection: some View {
        ScaleCard(
            header: .init(
                title: "Overdue Doses",
                subtitle: "\(viewModel.overdueDoses.count) doses",
                icon: "exclamationmark.triangle.fill",
                iconColor: .scaleError
            )
        ) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(viewModel.overdueDoses, id: \.id) { dose in
                    DoseRow(dose: dose, urgency: .overdue) {
                        Task { await viewModel.administerDose(dose) }
                    } onSkip: {
                        Task { await viewModel.skipDose(dose) }
                    }
                }
            }
        }
    }

    // MARK: - Doses Today Section

    private var dosesTodaySection: some View {
        ScaleCard(
            header: .init(
                title: "Today's Doses",
                subtitle: "\(viewModel.dosesToday.count) scheduled",
                icon: "clock.fill",
                iconColor: .nebulaGold
            )
        ) {
            VStack(spacing: ScaleSpacing.sm) {
                ForEach(viewModel.dosesToday, id: \.id) { dose in
                    DoseRow(dose: dose, urgency: .scheduled) {
                        Task { await viewModel.administerDose(dose) }
                    } onSkip: {
                        Task { await viewModel.skipDose(dose) }
                    }
                }
            }
        }
    }

    // MARK: - Active Treatments Section

    private var activeTreatmentsSection: some View {
        ScaleCard(
            header: .init(
                title: "Active Treatments",
                subtitle: "\(viewModel.activeTreatments.count) treatments",
                icon: "pills.fill",
                iconColor: .nebulaMagenta
            )
        ) {
            VStack(spacing: ScaleSpacing.md) {
                ForEach(viewModel.activeTreatments, id: \.id) { treatment in
                    NavigationLink {
                        TreatmentDetailView(treatment: treatment)
                    } label: {
                        TreatmentRow(treatment: treatment)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Dose Row

struct DoseRow: View {
    let dose: MedicationDose
    let urgency: DoseUrgency
    let onAdminister: () -> Void
    let onSkip: () -> Void

    enum DoseUrgency {
        case overdue, scheduled, upcoming
    }

    private var treatmentPlan: TreatmentPlan? {
        dose.treatmentPlan
    }

    var body: some View {
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(urgencyColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: treatmentPlan?.medication?.medicationType.iconName ?? "pill")
                    .font(.system(size: 18))
                    .foregroundColor(urgencyColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(treatmentPlan?.animal?.name ?? "Unknown")
                    .font(.scaleHeadline)
                    .foregroundColor(.scaleTextPrimary)

                Text(treatmentPlan?.medication?.name ?? "")
                    .font(.scaleCaption)
                    .foregroundColor(.scaleTextSecondary)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(dose.scheduledTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 11))

                    if let hours = dose.hoursOverdue {
                        Text("(\(hours)h late)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.scaleError)
                    }
                }
                .foregroundColor(.scaleTextTertiary)
            }

            Spacer()

            // Actions
            HStack(spacing: ScaleSpacing.sm) {
                Button(action: onSkip) {
                    Image(systemName: "arrow.uturn.right")
                        .font(.system(size: 14))
                        .foregroundColor(.scaleTextTertiary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.cosmicDeep)
                        )
                }

                Button(action: onAdminister) {
                    Text("Give")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent)
                        .padding(.horizontal, ScaleSpacing.md)
                        .padding(.vertical, ScaleSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: ScaleRadius.sm)
                                .fill(ThemeManager.shared.currentTheme.primaryAccent.opacity(0.15))
                        )
                }
            }
        }
        .padding(.vertical, ScaleSpacing.xs)
    }

    private var urgencyColor: Color {
        switch urgency {
        case .overdue: return .scaleError
        case .scheduled: return .nebulaGold
        case .upcoming: return .nebulaCyan
        }
    }
}

// MARK: - Treatment Row

struct TreatmentRow: View {
    let treatment: TreatmentPlan

    var body: some View {
        HStack {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(ThemeManager.shared.currentTheme.primaryAccent.opacity(0.2), lineWidth: 4)
                    .frame(width: 48, height: 48)

                Circle()
                    .trim(from: 0, to: treatment.progressPercentage / 100)
                    .stroke(ThemeManager.shared.currentTheme.primaryAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(treatment.progressPercentage))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(treatment.animal?.name ?? "Unknown")
                        .font(.scaleHeadline)
                        .foregroundColor(.scaleTextPrimary)

                    Text(treatment.status.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(statusColor.opacity(0.15))
                        )
                }

                Text(treatment.medication?.name ?? "")
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextSecondary)

                HStack(spacing: ScaleSpacing.md) {
                    Label("\(treatment.completedDoses)/\(treatment.totalDoses ?? 0)", systemImage: "checkmark.circle")
                        .font(.scaleCaption)
                        .foregroundColor(.scaleTextTertiary)

                    Label(treatment.dosage, systemImage: "eyedropper")
                        .font(.scaleCaption)
                        .foregroundColor(.scaleTextTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.scaleTextTertiary)
        }
        .padding(.vertical, ScaleSpacing.xs)
    }

    private var statusColor: Color {
        switch treatment.status {
        case .active: return .nebulaCyan
        case .paused: return .nebulaGold
        case .completed: return .nebulaCyan
        case .discontinued: return .scaleError
        }
    }
}

// MARK: - Medication View Model

@MainActor
@Observable
final class MedicationViewModel: ObservableObject {
    // MARK: - Dependencies
    private let medicationService: MedicationService

    // MARK: - State
    var activeTreatments: [TreatmentPlan] = []
    var dosesToday: [MedicationDose] = []
    var overdueDoses: [MedicationDose] = []
    var isLoading = false
    var error: Error?

    var isEmpty: Bool {
        activeTreatments.isEmpty && dosesToday.isEmpty && overdueDoses.isEmpty
    }

    // MARK: - Init
    init(medicationService: MedicationService = .shared) {
        self.medicationService = medicationService
    }

    // MARK: - Load
    func load() async {
        isLoading = true
        defer { isLoading = false }

        await medicationService.refresh()

        activeTreatments = medicationService.activeTreatments
        dosesToday = medicationService.dosesToday
        overdueDoses = medicationService.overdueDoses
    }

    // MARK: - Actions
    func administerDose(_ dose: MedicationDose) async {
        do {
            try medicationService.administerDose(dose)
            await load()
        } catch {
            self.error = error
        }
    }

    func skipDose(_ dose: MedicationDose) async {
        do {
            try medicationService.skipDose(dose)
            await load()
        } catch {
            self.error = error
        }
    }
}

// MARK: - Preview

#Preview {
    MedicationView()
        .environmentObject(AppState())
}
