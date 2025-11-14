//
//  ExerciseTemplate.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//
import Foundation

struct ExerciseTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: String
    var defaultReps: Int?
    var defaultWeight: Double?

    init(
        id: UUID = UUID(),
        name: String,
        category: String = "Strength",
        defaultReps: Int? = nil,
        defaultWeight: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.defaultReps = defaultReps
        self.defaultWeight = defaultWeight
    }
}
