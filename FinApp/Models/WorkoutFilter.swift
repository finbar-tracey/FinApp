//
//  WorkoutFilter.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//
import Foundation

enum WorkoutFilter: String, CaseIterable, Identifiable {
    case all
    case strength
    case cardio
    case other

    var id: Self { self }

    var label: String {
        switch self {
        case .all: return "All"
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .other: return "Other"
        }
    }
}
