import Foundation
import Combine

final class WorkoutStore: ObservableObject {
    @Published private(set) var workouts: [Workout] = []

    private let key = "workouts"

    init() { load(); sort() }

    // MARK: - CRUD
    func add(_ workout: Workout) {
        workouts.insert(workout, at: 0)
        sort()
        save()
    }

    func update(_ workout: Workout) {
        if let i = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[i] = workout
            sort()
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        for o in offsets.sorted(by: >) { workouts.remove(at: o) }
        save()
    }

    // MARK: - Helpers
    private func sort() {
        workouts.sort { $0.date > $1.date }
    }

    // MARK: - Persistence
    private func save() {
        do {
            let data = try JSONEncoder().encode(workouts)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to save workouts: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        do {
            workouts = try JSONDecoder().decode([Workout].self, from: data)
        } catch {
            print("Failed to load workouts: \(error)")
            workouts = []
        }
    }
}
