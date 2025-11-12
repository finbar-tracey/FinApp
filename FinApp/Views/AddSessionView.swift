//
//  AddSessionView.swift
//  FinApp
//
//  Created by Finbar Tracey on 12/11/2025.
//
import SwiftUI

struct AddSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: WorkoutStore

    var existing: WorkoutSession?

    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var duration: String = ""    // optional
    @State private var notes: String = ""
    @State private var exercises: [Exercise] = []

    init(existing: WorkoutSession? = nil) {
        self.existing = existing
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Details") {
                    TextField("Session title (e.g. Push Day)", text: $title)
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Duration (min, optional)", text: $duration)
                        .keyboardType(.numberPad)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                Section("Exercises") {
                    if exercises.isEmpty {
                        Text("No exercises. Tap “Add exercise”.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(exercises) { ex in
                            NavigationLink {
                                EditExerciseView(exercise: binding(for: ex))
                            } label: {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(ex.name).font(.headline)
                                        Spacer()
                                        Text(ex.category).foregroundStyle(.secondary)
                                    }
                                    Text("\(ex.sets.count) sets")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { idx in
                            exercises.remove(atOffsets: idx)
                        }
                    }

                    Button {
                        exercises.append(Exercise(name: "New Exercise"))
                    } label: {
                        Label("Add exercise", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle(existing == nil ? "Add Session" : "Edit Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existing == nil ? "Save" : "Update") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || exercises.isEmpty)
                }
            }
            .onAppear {
                guard let s = existing else { return }
                title = s.title
                date = s.date
                duration = s.durationMinutes.map(String.init) ?? ""
                notes = s.notes ?? ""
                exercises = s.exercises
            }
        }
    }

    private func save() {
        let dur = Int(duration) // may be nil
        var session = existing ?? WorkoutSession(title: title, date: date, durationMinutes: dur, notes: notes, exercises: exercises)
        session.title = title.trimmingCharacters(in: .whitespaces)
        session.date = date
        session.durationMinutes = dur
        session.notes = notes.isEmpty ? nil : notes
        session.exercises = exercises

        if existing == nil { store.add(session) } else { store.update(session) }
        dismiss()
    }

    private func binding(for exercise: Exercise) -> Binding<Exercise> {
        Binding(
            get: { exercises.first(where: { $0.id == exercise.id }) ?? exercise },
            set: { updated in
                if let idx = exercises.firstIndex(where: { $0.id == updated.id }) {
                    exercises[idx] = updated
                }
            }
        )
    }
}

struct EditExerciseView: View {
    @Binding var exercise: Exercise
    @State private var newWeight = ""
    @State private var newReps = ""

    var body: some View {
        List {
            Section("Exercise") {
                TextField("Name", text: $exercise.name)
                TextField("Category", text: $exercise.category)
            }

            Section("Sets") {
                if exercise.sets.isEmpty {
                    Text("No sets yet").foregroundStyle(.secondary)
                } else {
                    ForEach(exercise.sets) { set in
                        HStack {
                            Text(set.weight.map { "\(Int($0)) kg" } ?? "BW")
                            Spacer()
                            Text("\(set.reps) reps")
                        }
                    }
                    .onDelete { idx in
                        exercise.sets.remove(atOffsets: idx)
                    }
                }

                HStack {
                    TextField("Weight kg (optional)", text: $newWeight)
                        .keyboardType(.decimalPad)
                    TextField("Reps", text: $newReps)
                        .keyboardType(.numberPad)
                    Button {
                        let w = Double(newWeight)
                        let r = Int(newReps) ?? 0
                        guard r > 0 else { return }
                        exercise.sets.append(ExerciseSet(weight: w, reps: r))
                        newWeight = ""
                        newReps = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(Int(newReps) == nil || Int(newReps) == 0)
                }
            }
        }
        .navigationTitle("Edit Exercise")
    }
}
