import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var store: WorkoutStore

    @State private var showingAdd = false
    @State private var editing: WorkoutSession? = nil
    @State private var search = ""

    private var filtered: [WorkoutSession] {
        let t = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return store.sessions }
        return store.sessions.filter { s in
            s.title.localizedCaseInsensitiveContains(t) ||
            s.exercises.contains(where: { $0.name.localizedCaseInsensitiveContains(t) || $0.category.localizedCaseInsensitiveContains(t) })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filtered.isEmpty {
                    Section {
                        Text("No sessions yet. Tap + to add your first workout.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        ForEach(filtered) { s in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(s.title).font(.headline)
                                    Spacer()
                                    Text(s.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                HStack(spacing: 14) {
                                    Label("\(s.exercises.count) exercises", systemImage: "dumbbell")
                                    Label("\(totalSets(s)) sets", systemImage: "number")
                                    if let d = s.durationMinutes { Label("\(d) min", systemImage: "clock") }
                                    if volumeKg(s) > 0 { Label("\(Int(volumeKg(s))) kg", systemImage: "scalemass") }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { editing = s }
                            .swipeActions {
                                Button("Edit") { editing = s }.tint(.blue)
                                Button(role: .destructive) {
                                    if let i = store.sessions.firstIndex(of: s) {
                                        store.delete(at: IndexSet(integer: i))
                                    }
                                } label: { Text("Delete") }
                            }
                        }
                        .onDelete(perform: store.delete)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .searchable(text: $search)
            .sheet(isPresented: $showingAdd) { AddSessionView().environmentObject(store) }
            .sheet(item: $editing) { s in AddSessionView(existing: s).environmentObject(store) }
        }
    }

    private func totalSets(_ s: WorkoutSession) -> Int {
        s.exercises.map { $0.sets.count }.reduce(0, +)
    }

    private func volumeKg(_ s: WorkoutSession) -> Double {
        s.exercises.flatMap { $0.sets }
            .compactMap { set -> Double? in
                guard let w = set.weight else { return nil }
                return w * Double(set.reps)
            }
            .reduce(0, +)
    }
}
