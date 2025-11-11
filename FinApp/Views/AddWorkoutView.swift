import SwiftUI

struct AddWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: WorkoutStore

    /// If set, we’re editing this workout
    var existing: Workout?

    @State private var name = ""
    @State private var weight = ""
    @State private var reps = ""
    @State private var category = "Strength"
    @State private var duration = ""
    @State private var date = Date()

    private let categories = ["Strength", "Hypertrophy", "Cardio", "Mobility", "Other"]

    init(existing: Workout? = nil) {
        self.existing = existing
    }

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
                    TextField("Weight (kg)", text: $weight).keyboardType(.decimalPad)
                    TextField("Reps", text: $reps).keyboardType(.numberPad)
                    TextField("Duration (min)", text: $duration).keyboardType(.numberPad)
                }
            }
            .navigationTitle(existing == nil ? "Add Workout" : "Edit Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existing == nil ? "Save" : "Update") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                guard let w = existing else { return }
                name = w.name
                weight = String(w.weight)
                reps = String(w.reps)
                category = w.category
                duration = String(w.durationMinutes)
                date = w.date
            }
        }
    }

    private var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return Double(weight) != nil && Int(reps) != nil && Int(duration) != nil
    }

    private func save() {
        guard let w = Double(weight), let r = Int(reps), let d = Int(duration) else { return }

        if var toUpdate = existing {
            toUpdate.name = name.trimmingCharacters(in: .whitespaces)
            toUpdate.weight = w
            toUpdate.reps = r
            toUpdate.category = category
            toUpdate.durationMinutes = d
            toUpdate.date = date
            store.update(toUpdate)
        } else {
            let new = Workout(
                name: name.trimmingCharacters(in: .whitespaces),
                weight: w,
                reps: r,
                category: category,
                durationMinutes: d,
                date: date
            )
            store.add(new)
        }
        dismiss()
    }
}
