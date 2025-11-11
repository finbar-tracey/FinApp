import SwiftUI

struct GoalsView: View {
    @AppStorage("weeklyWorkoutsTarget") private var weeklyWorkoutsTarget: Int = 3
    @AppStorage("benchGoalKg") private var benchGoalKg: Int = 80
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
                        Text("Bench: \(benchGoalKg) kg")
                    }
                }
                Section("Units") {
                    Toggle("Use lbs (instead of kg)", isOn: $useImperial)
                }
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
