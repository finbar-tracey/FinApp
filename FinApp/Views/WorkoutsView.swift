import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var store: WorkoutStore

    @State private var showingAdd = false
    @State private var editing: WorkoutSession? = nil
    @State private var search = ""
    @State private var sortNewestFirst = true
    @State private var selectedFilter: WorkoutFilter = .all

    // MARK: - Filtering helpers

    private func matchesFilter(_ session: WorkoutSession) -> Bool {
        if selectedFilter == .all {
            return true
        }

        let primaryCategory = session.exercises.first?.category.lowercased() ?? ""

        let isStrength = primaryCategory.contains("strength") || primaryCategory.contains("weight")
        let isCardio = primaryCategory.contains("cardio") || primaryCategory.contains("run") || primaryCategory.contains("bike")

        switch selectedFilter {
        case .all:
            return true
        case .strength:
            return isStrength
        case .cardio:
            return isCardio
        case .other:
            return !isStrength && !isCardio
        }
    }

    private func matchesSearch(_ session: WorkoutSession, term: String) -> Bool {
        if term.isEmpty {
            return true
        }

        if session.title.localizedCaseInsensitiveContains(term) {
            return true
        }

        for exercise in session.exercises {
            if exercise.name.localizedCaseInsensitiveContains(term) {
                return true
            }
            if exercise.category.localizedCaseInsensitiveContains(term) {
                return true
            }
        }

        return false
    }

    private func sortOrder(lhs: WorkoutSession, rhs: WorkoutSession) -> Bool {
        if sortNewestFirst {
            return lhs.date > rhs.date
        } else {
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private var filteredAndSorted: [WorkoutSession] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)

        var result: [WorkoutSession] = []

        // Filter (search + category)
        for session in store.sessions {
            if !matchesSearch(session, term: term) {
                continue
            }
            if !matchesFilter(session) {
                continue
            }
            result.append(session)
        }

        // Sort
        result.sort(by: sortOrder(lhs:rhs:))

        return result
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if store.sessions.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)

                        Text("No workouts yet")
                            .font(.headline)

                        Text("Tap the + button to add your first workout session.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    List {
                        // Summary
                        Section {
                            WorkoutSummaryHeader(sessions: store.sessions)
                                .listRowInsets(EdgeInsets())
                        }

                        // Filters + sort
                        Section {
                            WorkoutFilterSortBar(
                                selectedFilter: $selectedFilter,
                                sortNewestFirst: $sortNewestFirst,
                                sessionCount: filteredAndSorted.count
                            )
                        }

                        // Sessions
                        Section {
                            ForEach(filteredAndSorted) { session in
                                NavigationLink {
                                    WorkoutSessionDetailView(sessionID: session.id)
                                        .environmentObject(store)
                                } label: {
                                    WorkoutSessionRow(session: session)
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .swipeActions {
                                    Button("Edit") { editing = session }
                                        .tint(.blue)

                                    Button {
                                        duplicate(session)
                                    } label: {
                                        Label("Duplicate", systemImage: "plus.square.on.square")
                                    }
                                    .tint(.green)

                                    Button(role: .destructive) {
                                        if let index = store.sessions.firstIndex(of: session) {
                                            store.delete(at: IndexSet(integer: index))
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            .onDelete(perform: store.delete)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add workout")
                }
            }
            .searchable(text: $search, prompt: "Search by title or exercise")
            .sheet(isPresented: $showingAdd) {
                AddSessionView()
                    .environmentObject(store)
            }
            .sheet(item: $editing) { session in
                AddSessionView(existing: session)
                    .environmentObject(store)
            }
        }
    }

    // MARK: - Actions

    private func duplicate(_ session: WorkoutSession) {
        store.duplicate(session)
    }
}

