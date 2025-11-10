import SwiftUI

struct GoalsView: View {
    // Super simple placeholder using @AppStorage (UserDefaults under the hood)
    @AppStorage("weeklyWorkoutsTarget") private var weeklyWorkoutsTarget: Int = 3
    @AppStorage("benchGoalKg") private var benchGoalKg: Int = 80

    var body: some View {
        Form {
            Section("Weekly Target") {
                Stepper(value: $weeklyWorkoutsTarget, in: 1...14) {
                    Text("\(weeklyWorkoutsTarget) workouts / week")
                }
            }
            Section("Strength Goals") {
                Stepper(value: $benchGoalKg, in: 20...300, step: 5) {
                    Text("Bench: \(benchGoalKg) kg")
                }
            }
            Section {
                Text("Progress summary appears here as you log workouts.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Goals")
    }
}
