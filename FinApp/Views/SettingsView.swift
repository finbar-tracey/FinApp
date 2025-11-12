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
    // Units (used across app)
    @AppStorage("useImperial") private var useImperial = false

    // Sleep
    @AppStorage("sleepSourcePreferenceRaw") private var sleepSourcePreferenceRaw: String = SleepSourcePreference.auto.rawValue
    @AppStorage("customSleepBundleId") private var customSleepBundleId: String = "" // advanced users
    @State private var detectedPreferred: String? = nil
    @EnvironmentObject var hk: HealthKitManager

    // Timer preferences (moved from TimerView)
    @AppStorage("enableBeeps") private var enableBeeps = true
    @AppStorage("enableHaptics") private var enableHaptics = true

    @Environment(\.dismiss) private var dismiss

    private var sleepPreference: SleepSourcePreference {
        SleepSourcePreference.allCases.first(where: { $0.rawValue == sleepSourcePreferenceRaw }) ?? .auto
    }

    var body: some View {
        NavigationStack {
            Form {
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                hk.detectPreferredSleepSourceBundleId { bid in
                    detectedPreferred = bid ?? "None"
                }
            }
        }
    }
}
