//
//  DashboardView.swift
//  FinApp
//
//  Created by Finbar Tracey on 11/11/2025.
//

import SwiftUI

struct DashboardView: View {
    // Stores
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var health: HealthStore
    @EnvironmentObject var hk: HealthKitManager

    // Settings
    @AppStorage("useImperial") private var useImperial = false
    @AppStorage("sleepSourcePreferenceRaw") private var sleepSourcePreferenceRaw: String = SleepSourcePreference.auto.rawValue
    @AppStorage("customSleepBundleId") private var customSleepBundleId: String = ""
    @AppStorage("weeklyWorkoutsTarget") private var weeklyWorkoutsTarget: Int = 3
    @AppStorage("weeklyStepsTarget") private var weeklyStepsTarget: Int = 70_000 // 10k/day default

    // UI State
    @State private var syncing = false
    @State private var sleepBreakdown: SleepBreakdown?
    @State private var loadingBreakdown = false
    @State private var navPath = NavigationPath()

    private var sleepPreference: SleepSourcePreference {
        SleepSourcePreference.allCases.first(where: { $0.rawValue == sleepSourcePreferenceRaw }) ?? .auto
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView {
                VStack(spacing: 16) {

                    // MARK: Header: Progress Rings (Weekly goals)
                    headerRings

                    // MARK: Today Cards (Activity + Sleep)
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 16) {
                        todayCard
                        sleepCard
                    }
                    .padding(.horizontal)

                    // MARK: Trends Card
                    trendsCard
                        .padding(.horizontal)

                    // MARK: Actions Row
                    actionsRow
                        .padding(.horizontal)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                            .environmentObject(hk)
                            .environmentObject(store)
                            .environmentObject(health)
                    } label: { Image(systemName: "gearshape") }
                }
            }
            // Pull-to-refresh
            .refreshable {
                await withCheckedContinuation { cont in
                    syncing = true
                    hk.syncToday(into: health) { _ in
                        syncing = false
                        fetchSleepBreakdownUsingSettings()
                        cont.resume()
                    }
                }
            }
            .onAppear {
                if hk.isAuthorized { fetchSleepBreakdownUsingSettings() }
            }
            .onChange(of: sleepSourcePreferenceRaw) { _ in
                // Re-calc breakdown when user changes sleep source preference
                if hk.isAuthorized { fetchSleepBreakdownUsingSettings() }
            }
        }
    }

    // MARK: - Header Rings

    private var headerRings: some View {
        HStack(spacing: 16) {
            Card {
                RingProgressView(
                    progress: progressRatio(current: workoutsThisWeek(), target: weeklyWorkoutsTarget),
                    label: "Workouts",
                    valueText: "\(workoutsThisWeek())/\(weeklyWorkoutsTarget)"
                )
            }

            Card {
                RingProgressView(
                    progress: progressRatio(current: stepsThisWeek(), target: weeklyStepsTarget),
                    label: "Steps",
                    valueText: numberString(stepsThisWeek()) + "/\(numberString(weeklyStepsTarget))"
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Today Card

    private var todayCard: some View {
        Card(alignment: .leading) {
            HStack {
                Label("Today", systemImage: "sun.max.fill").font(.headline)
                Spacer()
                if syncing { ProgressView() }
            }
            Divider().opacity(0.15)

            // Workouts + Activity minutes
            HStack {
                Label("\(workoutsToday()) workouts", systemImage: "figure.strengthtraining.traditional")
                Spacer()
                Text("\(minutesToday()) min")
                    .foregroundStyle(.secondary)
            }

            // Weight & Steps
            HStack {
                if let w = weightToday() {
                    Label(weightText(w), systemImage: "scalemass")
                } else {
                    Label("—", systemImage: "scalemass")
                }
                Spacer()
                if let s = stepsTodayFromEntries() {
                    Label("\(numberString(s)) steps", systemImage: "figure.walk")
                } else {
                    Label("— steps", systemImage: "figure.walk")
                }
            }

            // RHR
            if let rhr = rhrToday() {
                Label("RHR \(rhr) bpm", systemImage: "heart.fill")
            } else {
                Label("RHR —", systemImage: "heart")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Sleep Card

    private var sleepCard: some View {
        Card(alignment: .leading) {
            HStack {
                Label("Sleep (last night)", systemImage: "bed.double.fill").font(.headline)
                Spacer()
                if loadingBreakdown || syncing { ProgressView() }
            }
            Divider().opacity(0.15)

            let total = sleepLastNight() ?? 0
            HStack {
                Text(formatSleep(total))
                    .font(.title3).bold()
                Spacer()
                QualityTag(text: qualityText(hours: total))
            }

            if let b = sleepBreakdown {
                SleepBreakdownView(breakdown: b)
                    .padding(.top, 4)
            } else {
                Text("No sleep stages available")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Trends Card

    private var trendsCard: some View {
        Card(alignment: .leading) {
            HStack {
                Label("Trends (7-day)", systemImage: "chart.line.uptrend.xyaxis").font(.headline)
                Spacer()
            }
            Divider().opacity(0.15)

            VStack(spacing: 8) {
                // Weight: lower generally better (or neutral) → goodIsDown = true
                TrendLabel(
                    title: "Weight",
                    value: latestWeightText(),
                    delta: weightDelta7d(),
                    goodIsDown: true
                )
                // RHR: lower often better → goodIsDown = true
                TrendLabel(
                    title: "Resting HR",
                    value: latestRHRText(),
                    delta: rhrDelta7d(),
                    goodIsDown: true
                )
                // Steps: higher better → goodIsDown = false
                TrendLabel(
                    title: "Steps",
                    value: numberString(stepsThisWeek()),
                    delta: Double(stepsThisWeek() - stepsLastWeek()),
                    goodIsDown: false
                )
            }
        }
    }

    // MARK: - Actions Row

    private var actionsRow: some View {
        Card {
            HStack(spacing: 12) {
                NavigationLink(value: "addHealth") {
                    actionButtonLabel(system: "plus.circle", text: "Log Health")
                }
                NavigationLink(value: "addSession") {
                    actionButtonLabel(system: "dumbbell", text: "Add Workout")
                }
                Button {
                    navPath.append("timer")
                } label: {
                    actionButtonLabel(system: "stopwatch", text: "Start Timer")
                }
            }
            .navigationDestination(for: String.self) { route in
                switch route {
                case "addHealth":
                    AddHealthEntryView().environmentObject(health)
                case "addSession":
                    AddSessionView().environmentObject(store)
                case "timer":
                    TimerView()
                default:
                    EmptyView()
                }
            }
        }
    }

    private func actionButtonLabel(system: String, text: String) -> some View {
        HStack {
            Image(systemName: system)
            Text(text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(.secondary.opacity(0.08)))
    }

    // MARK: - Sleep Breakdown Loader honoring Settings

    private func fetchSleepBreakdownUsingSettings() {
        loadingBreakdown = true

        // Custom override first
        let custom = customSleepBundleId.trimmingCharacters(in: .whitespaces)
        if !custom.isEmpty {
            hk.lastNightSleepBreakdown(preferSourceBundleId: custom) { b in
                self.sleepBreakdown = b
                self.loadingBreakdown = false
            }
            return
        }

        switch sleepPreference {
        case .exclusive:
            hk.lastNightExclusiveSleepBreakdown { b in
                self.sleepBreakdown = b
                self.loadingBreakdown = false
            }

        case .garmin:
            hk.detectPreferredSleepSourceBundleId { bid in
                let bundle = bid?.lowercased().contains("garmin") == true ? bid! : "com.garmin.connect"
                self.hk.lastNightSleepBreakdown(preferSourceBundleId: bundle) { br in
                    self.sleepBreakdown = br
                    self.loadingBreakdown = false
                }
            }

        case .apple:
            hk.detectPreferredSleepSourceBundleId { bid in
                let bundle = (bid?.lowercased().contains("watch") == true || (bid?.hasPrefix("com.apple") == true)) ? bid! : "com.apple.health"
                self.hk.lastNightSleepBreakdown(preferSourceBundleId: bundle) { br in
                    self.sleepBreakdown = br
                    self.loadingBreakdown = false
                }
            }

        case .auto:
            hk.detectPreferredSleepSourceBundleId { bid in
                if let b = bid {
                    self.hk.lastNightSleepBreakdown(preferSourceBundleId: b) { br in
                        if let br = br { self.sleepBreakdown = br }
                        else { self.hk.lastNightExclusiveSleepBreakdown { self.sleepBreakdown = $0 } }
                        self.loadingBreakdown = false
                    }
                } else {
                    self.hk.lastNightExclusiveSleepBreakdown { b in
                        self.sleepBreakdown = b
                        self.loadingBreakdown = false
                    }
                }
            }
        }
    }

    // MARK: - Calendar helpers

    private var cal: Calendar { Calendar.current }
    private var startOfToday: Date { cal.startOfDay(for: Date()) }
    private var startOfWeek: Date {
        cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? startOfToday
    }
    private var startOfLastWeek: Date {
        cal.date(byAdding: .day, value: -7, to: startOfWeek) ?? startOfWeek
    }

    // MARK: - Today stats (sessions)

    private func workoutsToday() -> Int {
        store.sessions.filter { $0.date >= startOfToday }.count
    }

    private func minutesToday() -> Int {
        store.sessions
            .filter { $0.date >= startOfToday }
            .compactMap(\.durationMinutes)
            .reduce(0, +)
    }

    private func weightToday() -> Double? {
        health.entries.first(where: { $0.date >= startOfToday })?.weightKg
    }

    private func rhrToday() -> Int? {
        health.entries.first(where: { $0.date >= startOfToday })?.restingHeartRate
    }

    private func sleepLastNight() -> Double? {
        health.entries.first(where: { $0.date >= startOfToday && $0.sleepHours != nil })?.sleepHours
    }

    private func stepsTodayFromEntries() -> Int? {
        health.entries.first(where: { $0.date >= startOfToday })?.steps
    }

    // MARK: - Week stats

    private func workoutsThisWeek() -> Int {
        store.sessions.filter { $0.date >= startOfWeek }.count
    }

    private func stepsThisWeek() -> Int {
        health.entries
            .filter { $0.date >= startOfWeek }
            .compactMap { $0.steps }
            .reduce(0, +)
    }

    private func stepsLastWeek() -> Int {
        health.entries
            .filter { $0.date >= startOfLastWeek && $0.date < startOfWeek }
            .compactMap { $0.steps }
            .reduce(0, +)
    }

    // MARK: - Trend helpers (7-day deltas)

    private func latestWeightText() -> String {
        guard let w = latestWeightKg() else { return "—" }
        return weightText(w)
    }

    private func latestWeightKg() -> Double? {
        health.entries
            .sorted(by: { $0.date > $1.date })
            .compactMap { $0.weightKg }
            .first
    }

    private func weightDelta7d() -> Double {
        // delta = latest - average of previous up-to-7 entries (excluding latest)
        let weights = health.entries
            .sorted(by: { $0.date > $1.date })
            .compactMap { $0.weightKg }

        guard let latest = weights.first else { return 0 }
        let prev = Array(weights.dropFirst().prefix(7))
        guard !prev.isEmpty else { return 0 }
        let avgPrev = prev.reduce(0, +) / Double(prev.count)
        let delta = latest - avgPrev
        // If using imperial, present delta in lbs equivalence for display in TrendLabel
        return useImperial ? delta * 2.2046226218 : delta
    }

    private func latestRHRText() -> String {
        if let r = health.entries
            .sorted(by: { $0.date > $1.date })
            .compactMap({ $0.restingHeartRate })
            .first { return "\(r) bpm" }
        return "—"
    }

    private func rhrDelta7d() -> Double {
        let values = health.entries
            .sorted(by: { $0.date > $1.date })
            .compactMap { $0.restingHeartRate }

        guard let latest = values.first else { return 0 }
        let prev = Array(values.dropFirst().prefix(7))
        guard !prev.isEmpty else { return 0 }
        let avgPrev = Double(prev.reduce(0, +)) / Double(prev.count)
        return Double(latest) - avgPrev
    }

    // MARK: - Formatters & small helpers

    private func weightText(_ kg: Double) -> String {
        if useImperial {
            let lbs = kg * 2.2046226218
            return "\(Int(round(lbs))) lb"
        }
        return "\(String(format: "%.1f", kg)) kg"
    }

    private func formatSleep(_ hours: Double) -> String {
        let totalMins = Int(round(hours * 60))
        let h = totalMins / 60
        let m = totalMins % 60
        return m == 0 ? "\(h) h" : "\(h) h \(m) min"
    }

    private func numberString(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private func progressRatio(current: Int, target: Int) -> Double {
        guard target > 0 else { return 0 }
        return min(max(Double(current) / Double(target), 0), 1)
    }

    private func qualityText(hours: Double) -> String {
        switch hours {
        case 8.0...: return "Great"
        case 6.5..<8.0: return "Good"
        case 0..<6.5: return "Okay"
        default: return "—"
        }
    }
}

// MARK: - Small UI building blocks

private struct Card<Content: View>: View {
    var alignment: HorizontalAlignment = .center
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: alignment, spacing: 12) {
            content
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.secondary.opacity(0.07)))
    }
}

struct RingProgressView: View {
    var progress: Double // 0...1
    var label: String
    var valueText: String

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().stroke(.secondary.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                    .stroke(.tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.35), value: progress)
                Text(valueText).font(.headline).monospacedDigit()
            }
            .frame(width: 110, height: 110)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct TrendLabel: View {
    let title: String
    let value: String
    let delta: Double
    let goodIsDown: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).bold().monospacedDigit()
            let up = delta > 0.0001
            let down = delta < -0.0001
            let color: Color = up
                ? (goodIsDown ? .red : .green)
                : (down ? (goodIsDown ? .green : .red) : .secondary)
            Image(systemName: up ? "arrow.up.right" : (down ? "arrow.down.right" : "arrow.right"))
                .foregroundStyle(color)
            Text(deltaText())
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .font(.subheadline)
    }

    private func deltaText() -> String {
        if abs(delta) < 0.0001 { return "—" }
        // Nicely rounded; if very large, show no decimals
        let absDelta = abs(delta)
        let fmt: String = absDelta >= 10 ? "%+.0f" : "%+.1f"
        return String(format: fmt, delta)
    }
}

private struct QualityTag: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(.green.opacity(0.15)))
            .foregroundStyle(.green)
    }
}
