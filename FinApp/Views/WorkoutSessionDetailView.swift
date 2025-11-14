import SwiftUI

struct WorkoutSessionDetailView: View {
    @EnvironmentObject var store: WorkoutStore

    let sessionID: UUID
    @State private var showingEdit = false

    // MARK: - Derived data

    private var currentSession: WorkoutSession? {
        store.sessions.first(where: { $0.id == sessionID })
    }

    private var totalExercises: Int {
        currentSession?.exercises.count ?? 0
    }

    private var totalSets: Int {
        guard let session = currentSession else { return 0 }
        var count = 0
        for exercise in session.exercises {
            count += exercise.sets.count
        }
        return count
    }

    private var volumeKg: Int {
        guard let session = currentSession else { return 0 }
        var total: Double = 0

        for exercise in session.exercises {
            for set in exercise.sets {
                if let weight = set.weight {
                    total += weight * Double(set.reps)
                }
            }
        }

        return Int(total)
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let session = currentSession {
                content(for: session)
            } else {
                Text("Workout not found")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(for session: WorkoutSession) -> some View {
        List {
            headerSection(for: session)

            ForEach(session.exercises) { exercise in
                exerciseSection(for: exercise)
            }
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let current = currentSession {
                AddSessionView(existing: current)
                    .environmentObject(store)
            } else {
                Text("This session was deleted.")
                    .padding()
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func headerSection(for session: WorkoutSession) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text(session.title)
                    .font(.title2.bold())

                Text(session.date.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let notes = session.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.subheadline.bold())
                        Text(notes)
                            .font(.subheadline)
                    }
                    .padding(.top, 4)
                }

                HStack(spacing: 16) {
                    statBox(title: "Exercises", value: "\(totalExercises)")
                    statBox(title: "Sets", value: "\(totalSets)")
                    if let duration = session.durationMinutes {
                        statBox(title: "Duration", value: "\(duration) min")
                    }
                    if volumeKg > 0 {
                        statBox(title: "Volume", value: "\(volumeKg) kg")
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func exerciseSection(for exercise: Exercise) -> some View {
        Section(header: Text(exercise.name)) {
            if exercise.sets.isEmpty {
                Text("No sets logged for this exercise.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                let bestIndex = bestSetIndex(for: exercise)

                ForEach(exercise.sets.indices, id: \.self) { index in
                    let set = exercise.sets[index]
                    setRow(set, index: index, isBest: bestIndex == index)
                }
            }
        }
    }

    // MARK: - Rows

    @ViewBuilder
    private func setRow(_ set: ExerciseSet, index: Int, isBest: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Set \(index + 1)")
                        .font(.subheadline.bold())

                    if isBest {
                        Text("PB")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 6) {
                    if let weight = set.weight {
                        Text("\(weight, specifier: "%.1f") kg")
                    } else {
                        Text("Bodyweight")
                    }
                    Text("× \(set.reps) reps")
                }
                .font(.subheadline)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let rpe = set.rpe {
                    Text("RPE \(rpe, specifier: "%.1f")")
                }
                if let rest = set.restSeconds {
                    Text("Rest \(rest)s")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func statBox(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Finds the "best" set for an exercise, using weight × reps.
    private func bestSetIndex(for exercise: Exercise) -> Int? {
        if exercise.sets.isEmpty {
            return nil
        }

        var bestIndex: Int?
        var bestScore: Double = -Double.infinity

        for (index, set) in exercise.sets.enumerated() {
            let weight = set.weight ?? 0
            let score = weight * Double(set.reps)

            if score > bestScore {
                bestScore = score
                bestIndex = index
            }
        }

        if bestScore <= 0 {
            return nil
        }

        return bestIndex
    }
}
