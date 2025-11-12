//
//  WorkoutSession.swift
//  FinApp
//
//  Created by Finbar Tracey on 12/11/2025.
//
import Foundation

struct ExerciseSet: Identifiable, Codable, Equatable {
    let id: UUID
    var weight: Double?     // kg (optional so bodyweight sets are fine)
    var reps: Int
    var restSeconds: Int?   // optional
    var rpe: Double?        // optional

    init(id: UUID = UUID(), weight: Double? = nil, reps: Int, restSeconds: Int? = nil, rpe: Double? = nil) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.restSeconds = restSeconds
        self.rpe = rpe
    }
}

struct Exercise: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: String
    var sets: [ExerciseSet]

    init(id: UUID = UUID(), name: String, category: String = "Strength", sets: [ExerciseSet] = []) {
        self.id = id
        self.name = name
        self.category = category
        self.sets = sets
    }
}

struct WorkoutSession: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var date: Date
    var durationMinutes: Int?  
    var notes: String?
    var exercises: [Exercise]

    init(id: UUID = UUID(),
         title: String,
         date: Date = Date(),
         durationMinutes: Int? = nil,
         notes: String? = nil,
         exercises: [Exercise] = []) {
        self.id = id
        self.title = title
        self.date = date
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.exercises = exercises
    }
}
