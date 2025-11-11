//
//  DashboardView.swift
//  FinApp
//
//  Created by Finbar Tracey on 11/11/2025.
//
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var health: HealthStore
    @EnvironmentObject var hk: HealthKitManager
    @AppStorage("useImperial") private var useImperial = false

    @State private var syncing = false
    @State private var authChecked = false

    var body: some View {
        NavigationStack {
            List {
                // HealthKit status & actions
                Section("Apple Health") {
                    if !hk.isAvailable {
                        Text("Health not available on this device.")
                            .foregroundStyle(.secondary)
                    } else if !hk.isAuthorized {
                        Button {
                            hk.requestAuthorization { _ in
                                authChecked = true
                            }
                        } label: {
                            Label("Connect to Apple Health", systemImage: "heart.text.square")
                        }
                    } else {
                        Button {
                            syncing = true
                            hk.syncToday(into: health) { _ in syncing = false }
                        } label: {
                            if syncing {
                                HStack {
                                    ProgressView()
                                    Text("Syncing…")
                                }
                            } else {
                                Label("Sync today’s weight, sleep & RHR", systemImage: "arrow.triangle.2.circlepath")
                            }
                        }
                    }
                }

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
                        if let sleep = sleepLastNight() {
                            Text("\(String(format: "%.1f", sleep)) h sleep").foregroundStyle(.secondary)

                        }
                    }
                    if let rhr = rhrToday() {
                        Label("RHR \(rhr) bpm", systemImage: "heart.fill")
                    }
                    if let s = stepsTodayFromEntries() {
                        Label("\(s) steps", systemImage: "figure.walk")
                    }
                }

                Section("This Week") {
                    Text("\(workoutsThisWeek()) workouts • \(minutesThisWeek()) min • \(stepsThisWeek()) steps")
                        .foregroundStyle(.secondary)
                }

                Section("Quick add") {
                    NavigationLink(value: "addHealth") {
                        Label("Log health metrics", systemImage: "plus.circle")
                    }
                    NavigationLink(value: "addWorkout") {
                        Label("Add workout", systemImage: "dumbbell")
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationDestination(for: String.self) { route in
                if route == "addHealth" {
                    AddHealthEntryView().environmentObject(health)
                } else if route == "addWorkout" {
                    AddWorkoutView().environmentObject(store)
                }
            }
        }
    }

    // MARK: - Helpers (dates)

    private var cal: Calendar { Calendar.current }
    private var startOfToday: Date { cal.startOfDay(for: Date()) }
    private var startOfWeek: Date {
        cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? startOfToday
    }

    // MARK: - Today stats

    private func workoutsToday() -> Int {
        store.workouts.filter { $0.date >= startOfToday }.count
    }

    private func minutesToday() -> Int {
        store.workouts.filter { $0.date >= startOfToday }.map(\.durationMinutes).reduce(0, +)
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

    // MARK: - Week stats

    private func workoutsThisWeek() -> Int {
        store.workouts.filter { $0.date >= startOfWeek }.count
    }

    private func minutesThisWeek() -> Int {
        store.workouts.filter { $0.date >= startOfWeek }.map(\.durationMinutes).reduce(0, +)
    }

    // MARK: - Formatters

    private func weightText(_ kg: Double) -> String {
        if useImperial {
            let lbs = kg * 2.2046226218
            return "\(Int(round(lbs))) lb"
        }
        return "\(String(format: "%.1f", kg)) kg"
    }
    
    // MARK: - Steps
    private func stepsTodayFromEntries() -> Int? {
        health.entries.first(where: { $0.date >= startOfToday })?.steps
    }

    private func stepsThisWeek() -> Int {
        health.entries
            .filter { $0.date >= startOfWeek }
            .compactMap { $0.steps }
            .reduce(0, +)
    }

}
