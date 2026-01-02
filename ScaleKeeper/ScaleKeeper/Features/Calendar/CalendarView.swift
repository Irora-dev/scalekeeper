import SwiftUI
import SwiftData
import ScaleCore
import ScaleUI

// MARK: - Calendar View

struct CalendarView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = CalendarViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @Namespace private var animation

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        NavigationStack {
            ZStack {
                ScaleBackground()

                ScrollView {
                    VStack(spacing: 0) {
                        // Month Header
                        monthHeader
                            .padding(.horizontal, ScaleSpacing.lg)
                            .padding(.top, ScaleSpacing.md)

                        // Weekday Labels
                        weekdayHeader
                            .padding(.horizontal, ScaleSpacing.md)
                            .padding(.top, ScaleSpacing.lg)

                        // Calendar Grid
                        calendarGrid
                            .padding(.horizontal, ScaleSpacing.md)
                            .padding(.top, ScaleSpacing.sm)

                        // Event Legend
                        legendView
                            .padding(.horizontal, ScaleSpacing.lg)
                            .padding(.top, ScaleSpacing.lg)

                        // Selected Day Events
                        selectedDayEventsSection
                            .padding(.horizontal, ScaleSpacing.lg)
                            .padding(.top, ScaleSpacing.lg)
                            .padding(.bottom, ScaleSpacing.xxxl)
                    }
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        appState.presentSheet(.quickNote)
                    } label: {
                        Image(systemName: "note.text.badge.plus")
                            .foregroundColor(.nebulaCyan)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentMonth = Date()
                            selectedDate = Date()
                        }
                    } label: {
                        Text("Today")
                            .font(.scaleButtonSmall)
                            .foregroundColor(themeManager.currentTheme.primaryAccent)
                    }
                }
            }
            .task {
                await viewModel.load()
            }
            .onChange(of: appState.dataRefreshTrigger) { _, _ in
                Task {
                    await viewModel.load()
                }
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.primaryAccent)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(themeManager.currentTheme.primaryAccent.opacity(0.1))
                    )
            }

            Spacer()

            VStack(spacing: 2) {
                Text(monthYearString(from: currentMonth))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.scaleTextPrimary)

                Text("\(viewModel.eventsInMonth(currentMonth).count) events")
                    .font(.scaleCaption)
                    .foregroundColor(themeManager.currentTheme.textTertiary)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.primaryAccent)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(themeManager.currentTheme.primaryAccent.opacity(0.1))
                    )
            }
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textTertiary)
                    .frame(height: 30)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = generateDaysInMonth(for: currentMonth)

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    CalendarDayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                        events: viewModel.eventsForDate(date)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDate = date
                        }
                        ScaleHaptics.light()
                    }
                } else {
                    Color.clear
                        .frame(height: 56)
                }
            }
        }
        .padding(.vertical, ScaleSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ScaleRadius.lg)
                .fill(Color.cardBackground.opacity(0.5))
        )
    }

    // MARK: - Legend View

    private var legendView: some View {
        HStack(spacing: ScaleSpacing.lg) {
            LegendItem(color: themeManager.currentTheme.primaryAccent, label: "Feeding")
            LegendItem(color: .nebulaMagenta, label: "Medication")
            LegendItem(color: .nebulaCyan, label: "Photo")
            LegendItem(color: .shedPink, label: "Shed")
            LegendItem(color: .nebulaGold, label: "Weight")
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Selected Day Events Section

    private var selectedDayEventsSection: some View {
        let events = viewModel.eventsForDate(selectedDate)

        return VStack(alignment: .leading, spacing: ScaleSpacing.md) {
            // Date Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDateString)
                        .font(.scaleHeadline)
                        .foregroundColor(.scaleTextPrimary)

                    Text("\(events.count) event\(events.count == 1 ? "" : "s")")
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textTertiary)
                }

                Spacer()

                if calendar.isDateInToday(selectedDate) {
                    Text("TODAY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.primaryAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(themeManager.currentTheme.primaryAccent.opacity(0.15))
                        )
                }
            }

            if events.isEmpty {
                emptyDayView
            } else {
                VStack(spacing: ScaleSpacing.sm) {
                    ForEach(events) { event in
                        CalendarEventRow(event: event)
                    }
                }
            }
        }
    }

    private var emptyDayView: some View {
        VStack(spacing: ScaleSpacing.md) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 40))
                .foregroundColor(themeManager.currentTheme.textTertiary.opacity(0.5))

            Text("No events on this day")
                .font(.scaleSubheadline)
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ScaleSpacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: ScaleRadius.md)
                .fill(Color.cardBackground.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: ScaleRadius.md)
                        .stroke(themeManager.currentTheme.borderColor.opacity(0.5), lineWidth: 1)
                )
        )
    }

    // MARK: - Helpers

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }

    private func generateDaysInMonth(for date: Date) -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        var currentDate = monthFirstWeek.start

        // Generate 6 weeks worth of days
        for _ in 0..<42 {
            if calendar.isDate(currentDate, equalTo: date, toGranularity: .month) {
                days.append(currentDate)
            } else if currentDate < monthInterval.start {
                days.append(nil) // Empty cell before month starts
            } else {
                days.append(nil) // Empty cell after month ends
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Trim trailing empty rows
        while days.count > 35 && days.suffix(7).allSatisfy({ $0 == nil }) {
            days.removeLast(7)
        }

        return days
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    @ObservedObject var themeManager = ThemeManager.shared
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let events: [CalendarEvent]
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Day Number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected || isToday ? .bold : .medium))
                    .foregroundColor(dayTextColor)

                // Event Indicators
                if !events.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(Array(eventColors.prefix(3)), id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 5, height: 5)
                        }
                        if events.count > 3 {
                            Text("+")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.textTertiary)
                        }
                    }
                } else {
                    Color.clear.frame(height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: ScaleRadius.sm)
                            .fill(themeManager.currentTheme.primaryAccent)
                    } else if isToday {
                        RoundedRectangle(cornerRadius: ScaleRadius.sm)
                            .stroke(themeManager.currentTheme.primaryAccent, lineWidth: 2)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var dayTextColor: Color {
        if isSelected {
            return themeManager.currentTheme.backgroundPrimary
        } else if isToday {
            return themeManager.currentTheme.primaryAccent
        } else if !isCurrentMonth {
            return themeManager.currentTheme.textTertiary.opacity(0.5)
        } else {
            return .scaleTextPrimary
        }
    }

    private var eventColors: [Color] {
        var colors: [Color] = []
        let types = Set(events.map { $0.type })

        if types.contains(.feeding) { colors.append(themeManager.currentTheme.primaryAccent) }
        if types.contains(.medication) { colors.append(.nebulaMagenta) }
        if types.contains(.photo) { colors.append(.nebulaCyan) }
        if types.contains(.shed) { colors.append(.shedPink) }
        if types.contains(.weight) || types.contains(.length) { colors.append(.nebulaGold) }

        return colors
    }
}

// MARK: - Calendar Event Row

struct CalendarEventRow: View {
    let event: CalendarEvent
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: ScaleSpacing.md) {
            // Event Icon
            ZStack {
                Circle()
                    .fill(event.type.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: event.type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(event.type.color)
            }

            // Event Details
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.scaleSubheadline)
                    .foregroundColor(.scaleTextPrimary)
                    .lineLimit(1)

                HStack(spacing: ScaleSpacing.xs) {
                    Text(event.animalName)
                        .font(.scaleCaption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    if let subtitle = event.subtitle {
                        Text("·")
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                        Text(subtitle)
                            .font(.scaleCaption)
                            .foregroundColor(themeManager.currentTheme.textTertiary)
                    }
                }
            }

            Spacer()

            // Time
            Text(event.formattedTime)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
        .padding(ScaleSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ScaleRadius.md)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: ScaleRadius.md)
                        .stroke(event.type.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(themeManager.currentTheme.textTertiary)
        }
    }
}

// MARK: - Calendar Event Model

struct CalendarEvent: Identifiable {
    let id: UUID
    let type: CalendarEventType
    let title: String
    let animalName: String
    let animalID: UUID
    let date: Date
    let subtitle: String?

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

enum CalendarEventType: String {
    case feeding
    case medication
    case photo
    case shed
    case weight
    case length
    case health
    case cleaning

    var icon: String {
        switch self {
        case .feeding: return "fork.knife"
        case .medication: return "pills.fill"
        case .photo: return "camera.fill"
        case .shed: return "humidity.fill"
        case .weight: return "scalemass.fill"
        case .length: return "ruler.fill"
        case .health: return "heart.text.square.fill"
        case .cleaning: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .feeding: return .terrariumGreen
        case .medication: return .nebulaMagenta
        case .photo: return .nebulaCyan
        case .shed: return .shedPink
        case .weight: return .nebulaGold
        case .length: return .nebulaGold
        case .health: return .scaleError
        case .cleaning: return .nebulaLavender
        }
    }

    var displayName: String {
        switch self {
        case .feeding: return "Feeding"
        case .medication: return "Medication"
        case .photo: return "Photo"
        case .shed: return "Shed"
        case .weight: return "Weight"
        case .length: return "Length"
        case .health: return "Health Note"
        case .cleaning: return "Cleaning"
        }
    }
}

// MARK: - Calendar View Model

@MainActor
@Observable
final class CalendarViewModel: ObservableObject {
    private let dataService: DataService

    var events: [CalendarEvent] = []
    var isLoading = false
    var error: Error?

    private let calendar = Calendar.current

    init(dataService: DataService = .shared) {
        self.dataService = dataService
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        var allEvents: [CalendarEvent] = []

        do {
            // Fetch all animals
            let animals = try dataService.fetchAllAnimals()
            let animalMap = Dictionary(uniqueKeysWithValues: animals.map { ($0.id, $0.name) })

            // Fetch feedings
            for animal in animals {
                let feedings = try dataService.fetchFeedings(for: animal, limit: 100)
                for feeding in feedings {
                    let event = CalendarEvent(
                        id: feeding.id,
                        type: .feeding,
                        title: feeding.feedingResponse.isSuccessful ? "Fed" : "Refused",
                        animalName: animal.name,
                        animalID: animal.id,
                        date: feeding.feedingDate,
                        subtitle: feeding.preyType.displayName
                    )
                    allEvents.append(event)
                }

                // Fetch weights
                let weights = try dataService.fetchWeights(for: animal, limit: 100)
                for weight in weights {
                    let event = CalendarEvent(
                        id: weight.id,
                        type: .weight,
                        title: "Weight Recorded",
                        animalName: animal.name,
                        animalID: animal.id,
                        date: weight.recordedAt,
                        subtitle: String(format: "%.0fg", weight.weightGrams)
                    )
                    allEvents.append(event)
                }

                // Fetch lengths
                let lengths = try dataService.fetchLengths(for: animal, limit: 100)
                for length in lengths {
                    let event = CalendarEvent(
                        id: length.id,
                        type: .length,
                        title: "Length Measured",
                        animalName: animal.name,
                        animalID: animal.id,
                        date: length.recordedAt,
                        subtitle: String(format: "%.1f cm", length.lengthCm)
                    )
                    allEvents.append(event)
                }

                // Fetch sheds
                let sheds = try dataService.fetchShedRecords(for: animal, limit: 100)
                for shed in sheds {
                    let event = CalendarEvent(
                        id: shed.id,
                        type: .shed,
                        title: "Shed",
                        animalName: animal.name,
                        animalID: animal.id,
                        date: shed.shedDate,
                        subtitle: shed.quality.displayName
                    )
                    allEvents.append(event)
                }

                // Fetch photos
                let photos = try dataService.fetchPhotos(for: animal, limit: 100)
                for photo in photos {
                    let event = CalendarEvent(
                        id: photo.id,
                        type: .photo,
                        title: "Photo Taken",
                        animalName: animal.name,
                        animalID: animal.id,
                        date: photo.capturedAt,
                        subtitle: photo.photoType.displayName
                    )
                    allEvents.append(event)
                }

                // Fetch health notes
                let healthNotes = try dataService.fetchHealthNotes(for: animal, limit: 100)
                for note in healthNotes {
                    let event = CalendarEvent(
                        id: note.id,
                        type: .health,
                        title: note.title,
                        animalName: animal.name,
                        animalID: animal.id,
                        date: note.recordedAt,
                        subtitle: note.content.map { String($0.prefix(30)) }
                    )
                    allEvents.append(event)
                }
            }

            // Sort by date (most recent first)
            events = allEvents.sorted { $0.date > $1.date }

        } catch {
            self.error = error
        }
    }

    func eventsForDate(_ date: Date) -> [CalendarEvent] {
        events.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
    }

    func eventsInMonth(_ date: Date) -> [CalendarEvent] {
        events.filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
        .environmentObject(AppState())
}
