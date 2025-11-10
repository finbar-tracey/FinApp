import Foundation
import SwiftUI
import Combine

final class WorkoutStore: ObservableObject {
    @Published private(set) var workouts: [Workout] = [] {
        didSet { save() }
    }

    private let key = "workouts"
    private var cancellables = Set<AnyCancellable>()

    init() { load() }

    func add(_ workout: Workout) {
        workouts.insert(workout, at: 0)
    }

    func delete(at offsets: IndexSet) {
        workouts.remove(atOffsets: offsets)
    }

    // MARK: - Persistence (UserDefaults JSON)
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
        }
    }
}
