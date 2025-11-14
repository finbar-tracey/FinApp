import Foundation
import Combine

// Legacy single-exercise Workout (for migration)
struct LegacyWorkout: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var weight: Double
    var reps: Int
    var category: String
    var durationMinutes: Int?
    var date: Date
}
extension WorkoutStore {
    func duplicate(_ session: WorkoutSession) {
        let copy = WorkoutSession(
            id: UUID(),
            title: session.title,
            date: Date(),   // new session = today
            durationMinutes: session.durationMinutes,
            notes: session.notes,
            exercises: session.exercises
        )

        // If your sessions is private(set), this still works because
        // you’re mutating inside the type.
        sessions.insert(copy, at: 0)

        // If you have a persistence method (e.g. save()), call it here.
        save()
    }
}

final class WorkoutStore: ObservableObject {
    @Published private(set) var sessions: [WorkoutSession] = []

    private let keyV2 = "workout_sessions_v2" // new key
    private let legacyKey = "workouts"        // old key

    init() {
        load()
        sort()
    }

    // MARK: - CRUD
    func add(_ session: WorkoutSession) {
        sessions.insert(session, at: 0)
        sort()
        save()
    }

    func update(_ session: WorkoutSession) {
        if let i = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[i] = session
            sort()
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        for o in offsets.sorted(by: >) { sessions.remove(at: o) }
        save()
    }
    
    

    // MARK: - Helpers
    private func sort() {
        sessions.sort { $0.date > $1.date }
    }

    // MARK: - Persistence
    private func save() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: keyV2)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }

    private func load() {
        let ud = UserDefaults.standard
        if let data = ud.data(forKey: keyV2) {
            do {
                sessions = try JSONDecoder().decode([WorkoutSession].self, from: data)
                return
            } catch {
                print("Failed to load sessions v2: \(error)")
                sessions = []
            }
        }

        // Try migrate legacy workouts -> sessions
        if let legacyData = ud.data(forKey: legacyKey) {
            do {
                let legacy = try JSONDecoder().decode([LegacyWorkout].self, from: legacyData)
                sessions = legacy.map { w in
                    let set = ExerciseSet(weight: w.weight, reps: w.reps)
                    let ex = Exercise(name: w.name, category: w.category, sets: [set])
                    return WorkoutSession(title: w.name,
                                          date: w.date,
                                          durationMinutes: w.durationMinutes, // may be nil
                                          exercises: [ex])
                }
                save() // write to new key
                return
            } catch {
                print("No legacy migration performed: \(error)")
            }
        }

        sessions = []
    }
}
