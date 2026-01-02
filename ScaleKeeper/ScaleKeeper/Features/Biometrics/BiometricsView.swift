import SwiftUI
import ScaleCore
import ScaleUI
import Charts

// MARK: - Biometrics View

struct BiometricsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: BiometricsViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedMetric: MetricType = .weight
    @State private var showingLogWeight = false
    @State private var showingLogLength = false

    init(animal: Animal) {
        _viewModel = StateObject(wrappedValue: BiometricsViewModel(animal: animal))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                ScrollView {
                    VStack(spacing: ScaleSpacing.lg) {
                        // Quick Stats
                        statsSection

                        // Body Condition
                        if let condition = viewModel.bodyCondition {
                            bodyConditionSection(condition)
                        }

                        // Metric Selector
                        metricSelector

                        // Growth Chart
                        chartSection

                        // History
                        historySection

                        // Quick Actions
                        actionsSection
                    }
                    .padding(ScaleSpacing.lg)
                }
            }
            .navigationTitle("Growth & Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingLogWeight = true
                        } label: {
                            Label("Log Weight", systemImage: "scalemass")
                        }

                        Button {
                            showingLogLength = true
                        } label: {
                            Label("Log Length", systemImage: "ruler")
                        }
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
            .sheet(isPresented: $showingLogWeight) {
                LogWeightView(animal: viewModel.animal) {
                    Task { await viewModel.load() }
                }
            }
            .sheet(isPresented: $showingLogLength) {
                LogLengthView(animal: viewModel.animal) {
                    Task { await viewModel.load() }
                }
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ScaleSpacing.md) {
            // Current Weight
            ScaleStatCard(
                title: "Current Weight",
                value: viewModel.currentWeight?.formattedWeight ?? "--",
                icon: "scalemass",
                iconColor: .nebulaCyan
            )

            // Current Length
            ScaleStatCard(
                title: "Current Length",
                value: viewModel.currentLength?.formattedLength ?? "--",
                icon: "ruler",
                iconColor: themeManager.currentTheme.primaryAccent
            )

            // Growth Rate
            if let growthRate = viewModel.growthRate {
                ScaleStatCard(
                    title: "Growth Rate",
                    value: growthRate.displayText,
                    icon: growthRate.trend.iconName,
                    iconColor: growthRateColor(growthRate.trend)
                )
            } else {
                ScaleStatCard(
                    title: "Growth Rate",
                    value: "--",
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .scaleTextTertiary
                )
            }

            // Last Measured
            ScaleStatCard(
                title: "Last Measured",
                value: viewModel.lastMeasuredText,
                icon: "clock",
                iconColor: .nebulaGold
            )
        }
    }

    // MARK: - Body Condition Section

    private func bodyConditionSection(_ condition: BodyConditionScore) -> some View {
        ScaleCard(
            header: .init(
                title: "Body Condition",
                icon: condition.condition.iconName,
                iconColor: bodyConditionColor(condition.condition)
            )
        ) {
            VStack(spacing: ScaleSpacing.md) {
                HStack {
                    // Condition indicator
                    ZStack {
                        Circle()
                            .fill(bodyConditionColor(condition.condition).opacity(0.15))
                            .frame(width: 60, height: 60)

                        Image(systemName: condition.condition.iconName)
                            .font(.system(size: 24))
                            .foregroundColor(bodyConditionColor(condition.condition))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(condition.condition.displayName)
                            .font(.scaleHeadline)
                            .foregroundColor(.scaleTextPrimary)

                        Text(condition.condition.description)
                            .font(.scaleCaption)
                            .foregroundColor(.scaleTextSecondary)

                        Text(String(format: "W/L Ratio: %.2f g/cm", condition.ratio))
                            .font(.scaleCaption)
                            .foregroundColor(.scaleTextTertiary)
                    }

                    Spacer()
                }

                // Visual gauge
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let position = min(max(condition.ratio / 7.0, 0.1), 0.9) // Map ratio to 0-1 range

                    ZStack(alignment: .leading) {
                        // Background gradient
                        LinearGradient(
                            colors: [.scaleWarning, .scaleSuccess, .scaleWarning],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 8)
                        .cornerRadius(4)

                        // Indicator
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                            .offset(x: width * position - 8)
                    }
                }
                .frame(height: 20)

                // Labels
                HStack {
                    Text("Underweight")
                        .font(.system(size: 10))
                        .foregroundColor(.scaleTextTertiary)
                    Spacer()
                    Text("Healthy")
                        .font(.system(size: 10))
                        .foregroundColor(.scaleTextTertiary)
                    Spacer()
                    Text("Overweight")
                        .font(.system(size: 10))
                        .foregroundColor(.scaleTextTertiary)
                }
            }
        }
    }

    // MARK: - Metric Selector

    private var metricSelector: some View {
        HStack(spacing: 0) {
            ForEach(MetricType.allCases, id: \.self) { metric in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMetric = metric
                    }
                } label: {
                    VStack(spacing: ScaleSpacing.xs) {
                        HStack(spacing: 4) {
                            Image(systemName: metric.iconName)
                                .font(.system(size: 12))
                            Text(metric.title)
                                .font(.scaleCaption)
                        }
                        .foregroundColor(selectedMetric == metric ? metric.color : .scaleTextTertiary)

                        Rectangle()
                            .fill(selectedMetric == metric ? metric.color : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, ScaleSpacing.md)
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        ScaleCard(
            header: .init(
                title: selectedMetric == .weight ? "Weight History" : "Length History",
                icon: "chart.xyaxis.line",
                iconColor: selectedMetric.color
            )
        ) {
            if selectedMetric == .weight && viewModel.growthData?.hasWeightData == true {
                weightChart
            } else if selectedMetric == .length && viewModel.growthData?.hasLengthData == true {
                lengthChart
            } else {
                emptyChartPlaceholder
            }
        }
    }

    private var weightChart: some View {
        VStack {
            if let data = viewModel.growthData {
                Chart {
                    ForEach(data.weights, id: \.id) { record in
                        LineMark(
                            x: .value("Date", record.recordedAt),
                            y: .value("Weight", record.weightGrams)
                        )
                        .foregroundStyle(Color.nebulaCyan)

                        PointMark(
                            x: .value("Date", record.recordedAt),
                            y: .value("Weight", record.weightGrams)
                        )
                        .foregroundStyle(Color.nebulaCyan)
                    }
                }
                .chartYAxisLabel("Weight (g)")
                .frame(height: 200)
            }
        }
    }

    private var lengthChart: some View {
        VStack {
            if let data = viewModel.growthData {
                Chart {
                    ForEach(data.lengths, id: \.id) { record in
                        LineMark(
                            x: .value("Date", record.recordedAt),
                            y: .value("Length", record.lengthCm)
                        )
                        .foregroundStyle(ThemeManager.shared.currentTheme.primaryAccent)

                        PointMark(
                            x: .value("Date", record.recordedAt),
                            y: .value("Length", record.lengthCm)
                        )
                        .foregroundStyle(ThemeManager.shared.currentTheme.primaryAccent)
                    }
                }
                .chartYAxisLabel("Length (cm)")
                .frame(height: 200)
            }
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: ScaleSpacing.md) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 40))
                .foregroundColor(.scaleTextTertiary.opacity(0.5))

            Text("No \(selectedMetric.title.lowercased()) data yet")
                .font(.scaleSubheadline)
                .foregroundColor(.scaleTextTertiary)

            Text("Log your first \(selectedMetric.title.lowercased()) to see growth trends")
                .font(.scaleCaption)
                .foregroundColor(.scaleTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    // MARK: - History Section

    private var historySection: some View {
        ScaleCard(
            header: .init(
                title: "Recent Measurements",
                icon: "list.bullet",
                iconColor: .scaleMuted
            )
        ) {
            if selectedMetric == .weight {
                weightHistoryList
            } else {
                lengthHistoryList
            }
        }
    }

    private var weightHistoryList: some View {
        VStack(spacing: ScaleSpacing.sm) {
            if viewModel.weightHistory.isEmpty {
                Text("No weight records")
                    .font(.scaleCaption)
                    .foregroundColor(.scaleTextTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ScaleSpacing.lg)
            } else {
                ForEach(viewModel.weightHistory.prefix(10), id: \.id) { record in
                    WeightHistoryRow(record: record, previousRecord: viewModel.previousWeight(before: record))
                }
            }
        }
    }

    private var lengthHistoryList: some View {
        VStack(spacing: ScaleSpacing.sm) {
            if viewModel.lengthHistory.isEmpty {
                Text("No length records")
                    .font(.scaleCaption)
                    .foregroundColor(.scaleTextTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ScaleSpacing.lg)
            } else {
                ForEach(viewModel.lengthHistory.prefix(10), id: \.id) { record in
                    LengthHistoryRow(record: record, previousRecord: viewModel.previousLength(before: record))
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        HStack(spacing: ScaleSpacing.md) {
            ScaleSecondaryButton("Log Weight", icon: "scalemass") {
                showingLogWeight = true
            }

            ScaleSecondaryButton("Log Length", icon: "ruler") {
                showingLogLength = true
            }
        }
    }

    // MARK: - Helpers

    private func growthRateColor(_ trend: GrowthTrend) -> Color {
        switch trend {
        case .growing: return .scaleSuccess
        case .stable: return .nebulaGold
        case .shrinking: return .scaleWarning
        }
    }

    private func bodyConditionColor(_ condition: BodyCondition) -> Color {
        switch condition {
        case .healthy: return .scaleSuccess
        case .underweight, .overweight: return .scaleWarning
        }
    }
}

// MARK: - Metric Type

enum MetricType: CaseIterable {
    case weight
    case length

    var title: String {
        switch self {
        case .weight: return "Weight"
        case .length: return "Length"
        }
    }

    var iconName: String {
        switch self {
        case .weight: return "scalemass"
        case .length: return "ruler"
        }
    }

    var color: Color {
        switch self {
        case .weight: return .nebulaCyan
        case .length: return .nebulaPurple
        }
    }
}

// MARK: - Weight History Row

struct WeightHistoryRow: View {
    let record: WeightRecord
    let previousRecord: WeightRecord?

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.nebulaCyan.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "scalemass")
                    .font(.system(size: 16))
                    .foregroundColor(.nebulaCyan)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(record.formattedWeight)
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)

                Text(record.recordedAt, style: .date)
                    .font(.scaleCaption)
                    .foregroundColor(.scaleTextTertiary)
            }

            Spacer()

            // Change indicator
            if let previous = previousRecord {
                let change = record.weightGrams - previous.weightGrams
                let percent = previous.weightGrams > 0 ? (change / previous.weightGrams) * 100 : 0

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10))
                        Text(String(format: "%+.0fg", change))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(change >= 0 ? .scaleSuccess : .scaleWarning)

                    Text(String(format: "%+.1f%%", percent))
                        .font(.system(size: 10))
                        .foregroundColor(.scaleTextTertiary)
                }
            }
        }
        .padding(.vertical, ScaleSpacing.xs)
    }
}

// MARK: - Length History Row

struct LengthHistoryRow: View {
    let record: LengthRecord
    let previousRecord: LengthRecord?

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(ThemeManager.shared.currentTheme.primaryAccent.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: record.measurementMethod.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: ScaleSpacing.sm) {
                    Text(record.formattedLength)
                        .font(.scaleSubheadline)
                        .foregroundColor(.scaleTextPrimary)

                    Text(record.measurementMethod.displayName)
                        .font(.system(size: 10))
                        .foregroundColor(ThemeManager.shared.currentTheme.primaryAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(ThemeManager.shared.currentTheme.primaryAccent.opacity(0.1))
                        )
                }

                Text(record.recordedAt, style: .date)
                    .font(.scaleCaption)
                    .foregroundColor(.scaleTextTertiary)
            }

            Spacer()

            // Change indicator
            if let previous = previousRecord {
                let change = record.lengthCm - previous.lengthCm
                let percent = previous.lengthCm > 0 ? (change / previous.lengthCm) * 100 : 0

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10))
                        Text(String(format: "%+.1fcm", change))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(change >= 0 ? .scaleSuccess : .scaleWarning)

                    Text(String(format: "%+.1f%%", percent))
                        .font(.system(size: 10))
                        .foregroundColor(.scaleTextTertiary)
                }
            }
        }
        .padding(.vertical, ScaleSpacing.xs)
    }
}

// MARK: - Biometrics View Model

@MainActor
@Observable
final class BiometricsViewModel: ObservableObject {
    let animal: Animal
    private let biometricsService: BiometricsService
    private let dataService: DataService

    // Weight data
    var weightHistory: [WeightRecord] = []
    var currentWeight: WeightRecord?

    // Length data
    var lengthHistory: [LengthRecord] = []
    var currentLength: LengthRecord?

    // Analysis
    var bodyCondition: BodyConditionScore?
    var growthRate: GrowthRate?
    var growthData: GrowthData?

    var lastMeasuredText: String {
        let weightDate = currentWeight?.recordedAt
        let lengthDate = currentLength?.recordedAt

        if let w = weightDate, let l = lengthDate {
            let latest = max(w, l)
            return latest.formatted(.relative(presentation: .named))
        } else if let w = weightDate {
            return w.formatted(.relative(presentation: .named))
        } else if let l = lengthDate {
            return l.formatted(.relative(presentation: .named))
        }
        return "Never"
    }

    init(animal: Animal, biometricsService: BiometricsService = .shared, dataService: DataService = .shared) {
        self.animal = animal
        self.biometricsService = biometricsService
        self.dataService = dataService
    }

    func load() async {
        do {
            // Load weight history
            weightHistory = try dataService.fetchWeights(for: animal)
            currentWeight = weightHistory.first

            // Load length history
            lengthHistory = try biometricsService.lengthHistory(for: animal)
            currentLength = lengthHistory.first

            // Calculate body condition
            bodyCondition = try biometricsService.bodyCondition(for: animal)

            // Calculate growth rate
            growthRate = try biometricsService.growthRate(for: animal)

            // Get growth data for charts
            growthData = try biometricsService.growthData(for: animal, months: 12)
        } catch {
            print("Failed to load biometrics: \(error)")
        }
    }

    func previousWeight(before record: WeightRecord) -> WeightRecord? {
        guard let index = weightHistory.firstIndex(where: { $0.id == record.id }),
              index + 1 < weightHistory.count else { return nil }
        return weightHistory[index + 1]
    }

    func previousLength(before record: LengthRecord) -> LengthRecord? {
        guard let index = lengthHistory.firstIndex(where: { $0.id == record.id }),
              index + 1 < lengthHistory.count else { return nil }
        return lengthHistory[index + 1]
    }
}

// MARK: - Preview

#Preview {
    BiometricsView(animal: Animal(name: "Monty", speciesID: UUID()))
        .environmentObject(AppState())
}
