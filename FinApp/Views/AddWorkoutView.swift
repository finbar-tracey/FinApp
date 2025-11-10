import SwiftUI

struct AddWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: WorkoutStore

    @State private var name = ""
    @State private var weight = ""
    @State private var reps = ""
    @State private var category = "Strength"
    @State private var duration = ""
    @State private var date = Date()

    private let categories = ["Strength", "Hypertrophy", "Cardio", "Mobility", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Exercise name (e.g. Bench Press)", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Performance") {
                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                    TextField("Reps", text: $reps)
                        .keyboardType(.numberPad)
                    TextField("Duration (min)", text: $duration)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return Double(weight) != nil && Int(reps) != nil && Int(duration) != nil
    }

    private func save() {
        guard
            let w = Double(weight),
            let r = Int(reps),
            let d = Int(duration)
        else { return }

        let workout = Workout(
            name: name.trimmingCharacters(in: .whitespaces),
            weight: w,
            reps: r,
            category: category,
            durationMinutes: d,
            date: date
        )
        store.add(workout)
        dismiss()
    }
}
