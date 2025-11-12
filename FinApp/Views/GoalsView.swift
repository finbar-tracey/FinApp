//
//  GoalsView.swift
//  FinApp
//

import SwiftUI

struct GoalsView: View {
    @AppStorage("weeklyWorkoutsTarget") private var weeklyWorkoutsTarget: Int = 3
    @AppStorage("benchGoalKg") private var benchGoalKg: Int = 80

    // Read global units from Settings
    @AppStorage("useImperial") private var useImperial = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Weekly Target") {
                    Stepper(value: $weeklyWorkoutsTarget, in: 1...14) {
                        Text("\(weeklyWorkoutsTarget) workouts / week")
                    }
                }
                Section("Strength Goals") {
                    Stepper(value: $benchGoalKg, in: 20...300, step: 5) {
                        Text("Bench: \(benchGoalLabel)")
                    }
                    Text("Stored in kg internally. Display follows your Units setting.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                // Units section removed; managed in SettingsView
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var benchGoalLabel: String {
        if useImperial {
            let lbs = Double(benchGoalKg) * 2.2046226218
            return "\(Int(round(lbs))) lb"
        } else {
            return "\(benchGoalKg) kg"
        }
    }
}
