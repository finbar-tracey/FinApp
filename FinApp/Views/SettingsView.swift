//
//  SettingsView.swift
//  FinApp
//
//  Created by Finbar Tracey on 12/11/2025.
//

import SwiftUI

enum SleepSourcePreference: String, CaseIterable, Identifiable {
    case auto        = "Auto (detect)"
    case garmin      = "Garmin only"
    case apple       = "Apple/Watch only"
    case exclusive   = "Combine sources (exclusive)"
    var id: String { rawValue }
}

struct SettingsView: View {
    // Env
    @EnvironmentObject var hk: HealthKitManager
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var health: HealthStore

    // Units (global)
    @AppStorage("useImperial") private var useImperial = false

    // Sleep
    @AppStorage("sleepSourcePreferenceRaw") private var sleepSourcePreferenceRaw: String = SleepSourcePreference.auto.rawValue
    @AppStorage("customSleepBundleId") private var customSleepBundleId: String = "" // advanced users
    @State private var detectedPreferred: String? = nil

    // Timer prefs
    @AppStorage("enableBeeps") private var enableBeeps = true
    @AppStorage("enableHaptics") private var enableHaptics = true

    // Optional display name (for initials)
    @AppStorage("profileName") private var profileName: String = "You"

    // Sync UI
    @State private var syncing = false

    private var sleepPreference: SleepSourcePreference {
        SleepSourcePreference.allCases.first(where: { $0.rawValue == sleepSourcePreferenceRaw }) ?? .auto
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Profile summary card
                Section {
                    ProfileSummaryView(
                        name: profileName,
                        useImperial: useImperial,
                        workoutsThisWeek: workoutsThisWeek(),
                        stepsThisWeek: stepsThisWeek(),
                        latestWeightText: latestWeightText(),
                        latestRHRText: latestRHRText(),
                        lastSyncText: lastSyncText(),
                        syncing: syncing,
                        onSync: {
                            syncing = true
                            hk.syncToday(into: health) { _ in syncing = false }
                        }
                    )
                }

                // MARK: Profile
                Section("Profile") {
                    TextField("Display name", text: $profileName, prompt: Text("Your name"))
                        .textInputAutocapitalization(.words)
                }

                // MARK: Units
                Section("Units") {
                    Toggle("Use imperial (lb, mi)", isOn: $useImperial)
                }

                // MARK: Sleep
                Section("Sleep Source") {
                    Picker("Preferred source", selection: $sleepSourcePreferenceRaw) {
                        ForEach(SleepSourcePreference.allCases) { pref in
                            Text(pref.rawValue).tag(pref.rawValue)
                        }
                    }
                    .pickerStyle(.menu)

                    if let detected = detectedPreferred, !detected.isEmpty {
                        LabeledContent("Detected last night") {
                            Text(detected).foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }

                    if sleepPreference == .apple || sleepPreference == .garmin {
                        Text("If no samples from your preferred source are found for last night, FinApp falls back to a safe merge.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    DisclosureGroup("Advanced") {
                        TextField("Custom bundle ID (optional)", text: $customSleepBundleId, prompt: Text("e.g. com.garmin.connect"))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                        Text("Override the sleep source bundle ID. Leave blank to auto-detect.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        hk.detectPreferredSleepSourceBundleId { bid in
                            detectedPreferred = bid ?? "None"
                        }
                    } label: {
                        Label("Detect last night’s source", systemImage: "magnifyingglass")
                    }
                }

                // MARK: Timer
                Section("Rest Timer") {
                    Toggle("Countdown beeps (3-2-1 & finish)", isOn: $enableBeeps)
                    Toggle("Haptics", isOn: $enableHaptics)
                }

                // MARK: Apple Health
                Section("Apple Health") {
                    Button {
                        hk.requestAuthorization { _ in }
                    } label: {
                        Label("Reconnect permissions", systemImage: "heart.text.square")
                    }
                }

                // MARK: About
                Section {
                    Link(destination: URL(string: "https://www.apple.com/legal/privacy/data/en/health-app/")!) {
                        Label("Health data & privacy", systemImage: "hand.raised")
                    }
                    LabeledContent("Version") {
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                hk.detectPreferredSleepSourceBundleId { bid in
                    detectedPreferred = bid ?? "None"
                }
            }
        }
    }

    // MARK: - Computed stats for the profile card

    private var cal: Calendar { .current }
    private var startOfWeek: Date {
        cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? cal.startOfDay(for: Date())
    }

    private func workoutsThisWeek() -> Int {
        store.sessions.filter { $0.date >= startOfWeek }.count
    }

    private func stepsThisWeek() -> Int {
        health.entries
            .filter { $0.date >= startOfWeek }
            .compactMap { $0.steps }
            .reduce(0, +)
    }

    private func latestWeightText() -> String {
        // most recent entry with weight
        guard let w = health.entries
            .sorted(by: { $0.date > $1.date })
            .compactMap({ $0.weightKg })
            .first else { return "—" }

        if useImperial {
            let lbs = w * 2.2046226218
            return "\(Int(round(lbs))) lb"
        } else {
            return String(format: "%.1f kg", w)
        }
    }

    private func latestRHRText() -> String {
        if let r = health.entries
            .sorted(by: { $0.date > $1.date })
            .compactMap({ $0.restingHeartRate })
            .first {
            return "\(r) bpm"
        }
        return "—"
    }

    private func lastSyncText() -> String {
        guard let last = health.entries.map(\.date).max() else { return "—" }
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: last)
    }
}
