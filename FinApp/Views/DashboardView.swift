//
//  DashboardView.swift
//  FinApp
//
//  Created by Finbar Tracey on 11/11/2025.
//
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: WorkoutStore      // uses sessions now
    @EnvironmentObject var health: HealthStore
    @EnvironmentObject var hk: HealthKitManager
    @AppStorage("useImperial") private var useImperial = false

    @State private var syncing = false
    @State private var sleepBreakdown: SleepBreakdown?
    @State private var loadingBreakdown = false

    // NEW: settings bindings for behavior
    @AppStorage("sleepSourcePreferenceRaw") private var sleepSourcePreferenceRaw: String = SleepSourcePreference.auto.rawValue
    @AppStorage("customSleepBundleId") private var customSleepBundleId: String = ""

    private var sleepPreference: SleepSourcePreference {
        SleepSourcePreference.allCases.first(where: { $0.rawValue == sleepSourcePreferenceRaw }) ?? .auto
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Apple Health
                Section("Apple Health") {
                    if !HealthKitManager.shared.isAvailable {
                        Text("Health not available on this device.")
                            .foregroundStyle(.secondary)
                    } else if !hk.isAuthorized {
                        Button {
                            hk.requestAuthorization { _ in
                                if hk.isAuthorized { fetchSleepBreakdownUsingSettings() }
                            }
                        } label: {
                            Label("Connect to Apple Health", systemImage: "heart.text.square")
                        }
                    } else {
                        Button {
                            syncing = true
                            hk.syncToday(into: health) { _ in
                                syncing = false
                                fetchSleepBreakdownUsingSettings()
                            }
                        } label: {
                            if syncing {
                                HStack { ProgressView(); Text("Syncing…") }
                            } else {
                                Label("Sync today’s weight, sleep, RHR & steps",
                                      systemImage: "arrow.triangle.2.circlepath")
                            }
                        }
                    }
                }

                // MARK: - Today
                Section("Today") {
                    HStack {
                        Label("\(workoutsToday()) workouts", systemImage: "figure.strengthtraining.traditional")
                        Spacer()
                        if let w = weightToday() {
                            Text(weightText(w)).foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        Label("\(minutesToday()) min activity", systemImage: "clock")
                        Spacer()
                        if let s = sleepLastNight() {
                            Text("\(formatSleep(s))").foregroundStyle(.secondary)
                        }
                    }
                    if let rhr = rhrToday() {
                        Label("RHR \(rhr) bpm", systemImage: "heart.fill")
                    }
                    if let steps = stepsTodayFromEntries() {
                        Label("\(steps) steps", systemImage: "figure.walk")
                    }
                }

                // MARK: - Sleep Stages (Last Night)
                if hk.isAuthorized {
                    Section("Sleep Stages (last night)") {
                        if loadingBreakdown {
                            HStack { ProgressView(); Text("Loading…") }
                        } else if let b = sleepBreakdown {
                            SleepBreakdownView(breakdown: b)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Sleep stages")
                                .accessibilityValue("\(Int(b.remPct*100)) percent REM, \(Int(b.deepPct*100)) percent Deep, \(Int(b.corePct*100)) percent Core")
                        } else {
                            Text("No sleep data").foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - This Week
                Section("This Week") {
                    Text("\(workoutsThisWeek()) workouts • \(minutesThisWeek()) min • \(stepsThisWeek()) steps")
                        .foregroundStyle(.secondary)
                }

                // MARK: - Quick add
                Section("Quick add") {
                    NavigationLink(value: "addHealth") {
                        Label("Log health metrics", systemImage: "plus.circle")
                    }
                    NavigationLink(value: "addSession") {
                        Label("Add workout session", systemImage: "dumbbell")
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView().environmentObject(hk)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationDestination(for: String.self) { route in
                switch route {
                case "addHealth":
                    AddHealthEntryView().environmentObject(health)
                case "addSession":
                    AddSessionView().environmentObject(store)
                default:
                    EmptyView()
                }
            }
            .onAppear {
                if hk.isAuthorized { fetchSleepBreakdownUsingSettings() }
            }
        }
    }

    // MARK: - Sleep Breakdown Loader honoring Settings
    private func fetchSleepBreakdownUsingSettings() {
        loadingBreakdown = true

        // If user specified a custom bundle, try that immediately.
        if !customSleepBundleId.trimmingCharacters(in: .whitespaces).isEmpty {
            hk.lastNightSleepBreakdown(preferSourceBundleId: customSleepBundleId) { b in
                if let b = b { self.sleepBreakdown = b; self.loadingBreakdown = false }
                else { self.fallbackExclusive() }
            }
            return
        }

        switch sleepPreference {
        case .exclusive:
            fallbackExclusive()

        case .garmin:
            // Try Garmin bundle if present; fall back to exclusive
            hk.detectPreferredSleepSourceBundleId { bundle in
                if let b = bundle, b.lowercased().contains("garmin") {
                    self.hk.lastNightSleepBreakdown(preferSourceBundleId: b) { br in
                        if let br = br { self.sleepBreakdown = br; self.loadingBreakdown = false }
                        else { self.fallbackExclusive() }
                    }
                } else {
                    // As a common default, try com.garmin.connect if detection missed
                    self.hk.lastNightSleepBreakdown(preferSourceBundleId: "com.garmin.connect") { br in
                        if let br = br { self.sleepBreakdown = br; self.loadingBreakdown = false }
                        else { self.fallbackExclusive() }
                    }
                }
            }

        case .apple:
            hk.detectPreferredSleepSourceBundleId { bundle in
                // Prefer anything Apple/Watch-like
                if let b = bundle, b.lowercased().contains("watch") || b.hasPrefix("com.apple") {
                    self.hk.lastNightSleepBreakdown(preferSourceBundleId: b) { br in
                        if let br = br { self.sleepBreakdown = br; self.loadingBreakdown = false }
                        else { self.fallbackExclusive() }
                    }
                } else {
                    // Fall back: try a generic Apple identifier (best-effort)
                    self.hk.lastNightSleepBreakdown(preferSourceBundleId: "com.apple.health") { br in
                        if let br = br { self.sleepBreakdown = br; self.loadingBreakdown = false }
                        else { self.fallbackExclusive() }
                    }
                }
            }

        case .auto:
            // Auto-detect (Garmin > Apple) then revert to exclusive
            hk.detectPreferredSleepSourceBundleId { bundle in
                if let b = bundle {
                    self.hk.lastNightSleepBreakdown(preferSourceBundleId: b) { br in
                        if let br = br { self.sleepBreakdown = br; self.loadingBreakdown = false }
                        else { self.fallbackExclusive() }
                    }
                } else {
                    self.fallbackExclusive()
                }
            }
        }
    }

    private func fallbackExclusive() {
        hk.lastNightExclusiveSleepBreakdown { b in
            self.sleepBreakdown = b
            self.loadingBreakdown = false
        }
    }

    // MARK: - Calendar helpers
    private var cal: Calendar { Calendar.current }
    private var startOfToday: Date { cal.startOfDay(for: Date()) }
    private var startOfWeek: Date {
        cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? startOfToday
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

    private func minutesThisWeek() -> Int {
        store.sessions
            .filter { $0.date >= startOfWeek }
            .compactMap(\.durationMinutes)
            .reduce(0, +)
    }

    private func stepsThisWeek() -> Int {
        health.entries
            .filter { $0.date >= startOfWeek }
            .compactMap { $0.steps }
            .reduce(0, +)
    }

    // MARK: - Formatters
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
}
