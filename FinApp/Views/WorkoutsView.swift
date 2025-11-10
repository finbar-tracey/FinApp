import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var showingAdd = false
    @State private var search = ""

    private var filtered: [Workout] {
        if search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return store.workouts
        }
        return store.workouts.filter {
            $0.name.localizedCaseInsensitiveContains(search)
            || $0.category.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filtered.isEmpty {
                    ContentUnavailableView("No Workouts",
                                           systemImage: "dumbbell",
                                           description: Text("Tap + to add your first workout."))
                } else {
                    ForEach(filtered) { w in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(w.name).font(.headline)
                                Spacer()
                                Text(w.category).font(.subheadline).foregroundStyle(.secondary)
                            }
                            HStack(spacing: 16) {
                                Label("\(Int(w.weight)) kg", systemImage: "scalemass")
                                Label("\(w.reps) reps", systemImage: "number")
                                Label("\(w.durationMinutes) min", systemImage: "clock")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            Text(w.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .onDelete(perform: store.delete)
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic))
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddWorkoutView()
                    .presentationDetents([.medium, .large])
            }
        }
    }
}
