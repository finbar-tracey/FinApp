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

    // Track which exercise should be opened in the editor
    @State private var activeExerciseID: UUID?

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
                            NavigationLink(
                                tag: ex.id,
                                selection: $activeExerciseID
                            ) {
                                EditExerciseView(exercise: binding(for: ex))
                                    .environmentObject(store)
                            } label: {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(ex.name.isEmpty ? "Unnamed exercise" : ex.name)
                                            .font(.headline)
                                        Spacer()
                                        Text(ex.category)
                                            .foregroundStyle(.secondary)
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
                        // Create a blank exercise and immediately open it
                        let newExercise = Exercise(name: "")
                        exercises.append(newExercise)
                        activeExerciseID = newExercise.id
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
        var session = existing ?? WorkoutSession(
            title: title,
            date: date,
            durationMinutes: dur,
            notes: notes,
            exercises: exercises
        )

        session.title = title.trimmingCharacters(in: .whitespaces)
        session.date = date
        session.durationMinutes = dur
        session.notes = notes.isEmpty ? nil : notes
        session.exercises = exercises

        if existing == nil {
            store.add(session)
        } else {
            store.update(session)
        }
        dismiss()
    }

    private func binding(for exercise: Exercise) -> Binding<Exercise> {
        Binding(
            get: {
                exercises.first(where: { $0.id == exercise.id }) ?? exercise
            },
            set: { updated in
                if let idx = exercises.firstIndex(where: { $0.id == updated.id }) {
                    exercises[idx] = updated
                }
            }
        )
    }
}

// MARK: - EditExerciseView with suggestions + autofill + last session sets

struct EditExerciseView: View {
    @EnvironmentObject var store: WorkoutStore
    @Binding var exercise: Exercise

    @State private var newWeight = ""
    @State private var newReps = ""

    // MARK: - Suggestions (from past sessions)

    /// All unique (name, category) pairs from past sessions
    private var allExerciseSuggestions: [(name: String, category: String)] {
        var seen = Set<String>()
        var result: [(String, String)] = []

        for session in store.sessions {
            for ex in session.exercises {
                let key = ex.name.trimmingCharacters(in: .whitespaces).lowercased()
                    + "|" +
                    ex.category.trimmingCharacters(in: .whitespaces).lowercased()
                if !seen.contains(key) {
                    seen.insert(key)
                    result.append((ex.name, ex.category))
                }
            }
        }

        // Sort alphabetically by name for consistency
        result.sort { lhs, rhs in
            lhs.0.localizedCaseInsensitiveCompare(rhs.0) == .orderedAscending
        }

        return result
    }

    // Filtered suggestions based on what the user typed in the name field
    private var filteredSuggestions: [(name: String, category: String)] {
        let rawQuery = exercise.name.trimmingCharacters(in: .whitespaces)
        let query = rawQuery.lowercased()

        // Only show suggestions after a couple of characters
        guard query.count >= 2 else { return [] }

        var matches: [(String, String)] = []
        for suggestion in allExerciseSuggestions {
            let nameLower = suggestion.name.lowercased()
            if nameLower.contains(query) && nameLower != query {
                matches.append(suggestion)
            }
        }

        if matches.count > 5 {
            matches = Array(matches.prefix(5))
        }

        return matches
    }

    // MARK: - Last session lookup (autofill + full history)

    /// Most recent exercise instance with this name across all saved sessions
    private var lastExerciseInstance: Exercise? {
        let nameKey = exercise.name.trimmingCharacters(in: .whitespaces).lowercased()
        guard !nameKey.isEmpty else { return nil }

        let sortedSessions = store.sessions.sorted { $0.date > $1.date }

        for session in sortedSessions {
            if let match = session.exercises.first(where: {
                $0.name.trimmingCharacters(in: .whitespaces).lowercased() == nameKey &&
                !$0.sets.isEmpty
            }) {
                return match
            }
        }

        return nil
    }

    /// Most recent set for this exercise name across all saved sessions
    private var lastSet: ExerciseSet? {
        lastExerciseInstance?.sets.last
    }

    /// All sets from the most recent session for this exercise
    private var lastSessionSets: [ExerciseSet]? {
        lastExerciseInstance?.sets
    }

    private var lastSetDescription: String? {
        guard let set = lastSet else { return nil }
        let weightText: String
        if let w = set.weight {
            if w == floor(w) {
                weightText = "\(Int(w)) kg"
            } else {
                weightText = "\(w) kg"
            }
        } else {
            weightText = "BW"
        }
        return "\(weightText) x \(set.reps)"
    }

    // MARK: - Body

    var body: some View {
        List {
            Section("Exercise") {
                TextField("Name", text: $exercise.name)
                TextField("Category", text: $exercise.category)
            }

            // Suggestions dropdown under the name
            if !filteredSuggestions.isEmpty {
                Section("Suggestions") {
                    ForEach(filteredSuggestions, id: \.0) { suggestion in
                        Button {
                            exercise.name = suggestion.name
                            exercise.category = suggestion.category
                            prefillFromLastSetIfEmpty()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.name)
                                        .font(.body)
                                    Text(suggestion.category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }

            // Last session: all sets + copy button
            if let sets = lastSessionSets, !sets.isEmpty {
                Section("Last session") {
                    ForEach(sets) { set in
                        HStack {
                            Text(weightDescription(for: set))
                            Spacer()
                            Text("\(set.reps) reps")
                        }
                        .font(.subheadline)
                    }

                    Button("Copy all sets") {
                        exercise.sets = sets
                        // Optionally also prefill add-set fields with last set
                        if let last = sets.last {
                            applySetToInputs(last)
                        }
                    }
                }
            } else if let lastDesc = lastSetDescription {
                // Fallback: if we somehow only have one set
                Section("Last time") {
                    HStack {
                        Text(lastDesc)
                        Spacer()
                        Button("Use") {
                            applyLastSet()
                        }
                    }
                    .font(.subheadline)
                }
            }

            Section("Sets") {
                if exercise.sets.isEmpty {
                    Text("No sets yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(exercise.sets) { set in
                        HStack {
                            Text(weightDescription(for: set))
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
                        // leave fields as-is so you can tap + repeatedly
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(Int(newReps) == nil || Int(newReps) == 0)
                }
            }
        }
        .navigationTitle("Edit Exercise")
        .onAppear {
            prefillFromLastSetIfEmpty()
        }
        .onChange(of: exercise.name) { _ in
            prefillFromLastSetIfEmpty()
        }
    }

    // MARK: - Helpers

    private func weightDescription(for set: ExerciseSet) -> String {
        if let w = set.weight {
            if w == floor(w) {
                return "\(Int(w)) kg"
            } else {
                return "\(w) kg"
            }
        } else {
            return "BW"
        }
    }

    // MARK: - Autofill helpers

    private func prefillFromLastSetIfEmpty() {
        guard newWeight.isEmpty && newReps.isEmpty,
              let set = lastSet else {
            return
        }
        applySetToInputs(set)
    }

    private func applyLastSet() {
        guard let set = lastSet else { return }
        applySetToInputs(set)
    }

    private func applySetToInputs(_ set: ExerciseSet) {
        if let w = set.weight {
            if w == floor(w) {
                newWeight = String(Int(w))
            } else {
                newWeight = String(w)
            }
        } else {
            newWeight = ""
        }
        newReps = String(set.reps)
    }
}
