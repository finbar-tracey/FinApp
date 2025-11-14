//
//  CardioEntry.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//

import Foundation

enum CardioType: String, Codable, CaseIterable, Identifiable {
    case run = "Run"
    case cycle = "Cycle"
    case row = "Row"
    case walk = "Walk"
    case other = "Other"

    var id: String { rawValue }
}

struct CardioEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var type: CardioType
    var date: Date
    var distanceKm: Double?
    var durationMinutes: Int
    var avgHeartRate: Int?
    var notes: String?

    init(
        id: UUID = UUID(),
        type: CardioType,
        date: Date = Date(),
        distanceKm: Double? = nil,
        durationMinutes: Int,
        avgHeartRate: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.type = type
        self.date = date
        self.distanceKm = distanceKm
        self.durationMinutes = durationMinutes
        self.avgHeartRate = avgHeartRate
        self.notes = notes
    }

    var paceMinutesPerKm: Double? {
        guard let distanceKm, distanceKm > 0 else { return nil }
        return Double(durationMinutes) / distanceKm
    }
}
