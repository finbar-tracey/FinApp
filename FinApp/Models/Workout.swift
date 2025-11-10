import Foundation

struct Workout: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var weight: Double
    var reps: Int
    var category: String
    var durationMinutes: Int
    var date: Date

    init(
        id: UUID = UUID(),
        name: String,
        weight: Double,
        reps: Int,
        category: String,
        durationMinutes: Int,
        date: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.weight = weight
        self.reps = reps
        self.category = category
        self.durationMinutes = durationMinutes
        self.date = date
    }
}
