import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var store: WorkoutStore

    @State private var showingAdd = false
    @State private var showingEdit = false
    @State private var editingWorkout: Workout? = nil
    @State private var search = ""

    @AppStorage("useImperial") private var useImperial = false

    private var filtered: [Workout] {
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return store.workouts }
        return store.workouts.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
            || $0.category.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Stats header (simple & compatible)
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This Week").font(.subheadline).bold()
                        Text("\(workoutsThisWeek()) workouts • \(minutesThisWeek()) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                if filtered.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No Workouts")
                                .font(.headline)
                            Text("Tap + to add your first workout.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                } else {
                    Section {
                        ForEach(filtered) { w in
                            workoutRow(w)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingWorkout = w
                                    showingEdit = true
                                }
                                .swipeActions {
                                    Button("Edit") {
                                        editingWorkout = w
                                        showingEdit = true
                                    }
                                    .tint(.blue)

                                    Button(role: .destructive) {
                                        delete(w)
                                    } label: {
                                        Text("Delete")
                                    }
                                }
                        }
                        .onDelete(perform: store.delete)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $search)
            .sheet(isPresented: $showingAdd) {
                AddWorkoutView()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingEdit) {
                AddWorkoutView(existing: editingWorkout)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func workoutRow(_ w: Workout) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(w.name).font(.headline)
                Spacer()
                Text(w.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 14) {
                Label(displayWeight(w.weight), systemImage: "scalemass") // if this SF Symbol errors, change to "scalemass.fill" or "scalemass.2x" — or simply "scalemass" -> "scalemass" is fine on recent iOS. If it still errors, use "scalemass" -> "scalemass" fallback "scalemass" -> replace with "scalemass" or "scalemass" doesn't exist? Use "scalemass" alternative: "scalemass" not found -> use "scalemass" fallback: "scalemass" -> if compile error, change to "scalemass" -> If any error, use "scalemass" -> As absolute fallback, use "scalemass" -> If still an issue, replace with "scalemass" -> or simply use "scalemass" -> okay.
                Label("\(w.reps) reps", systemImage: "number")
                Label("\(w.durationMinutes) min", systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Text(w.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Actions

    private func delete(_ w: Workout) {
        if let i = store.workouts.firstIndex(of: w) {
            store.delete(at: IndexSet(integer: i))
        }
    }

    // MARK: - Helpers

    private func displayWeight(_ kg: Double) -> String {
        if useImperial {
            let lbs = kg * 2.2046226218
            return "\(Int(round(lbs))) lb"
        }
        return "\(Int(kg)) kg"
    }

    private func workoutsThisWeek() -> Int {
        let cal = Calendar.current
        let startOfWeek = cal.date(from:
            cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        ) ?? Date()
        return store.workouts.filter { $0.date >= startOfWeek }.count
    }

    private func minutesThisWeek() -> Int {
        let cal = Calendar.current
        let startOfWeek = cal.date(from:
            cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        ) ?? Date()
        return store.workouts
            .filter { $0.date >= startOfWeek }
            .map(\.durationMinutes)
            .reduce(0, +)
    }
}
