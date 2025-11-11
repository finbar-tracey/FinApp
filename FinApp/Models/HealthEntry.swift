//
//  HealthEntry.swift
//  FinApp
//
//  Created by Finbar Tracey on 11/11/2025.
//
import Foundation

struct HealthEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date

    // Core metrics (all optional so you can log any subset)
    var weightKg: Double?
    var bodyFatPercent: Double?
    var restingHeartRate: Int?
    var sleepHours: Double?
    var waterLitres: Double?
    var systolicBP: Int?
    var diastolicBP: Int?
    var steps: Int?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weightKg: Double? = nil,
        bodyFatPercent: Double? = nil,
        restingHeartRate: Int? = nil,
        sleepHours: Double? = nil,
        waterLitres: Double? = nil,
        systolicBP: Int? = nil,
        diastolicBP: Int? = nil,
        steps: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.bodyFatPercent = bodyFatPercent
        self.restingHeartRate = restingHeartRate
        self.sleepHours = sleepHours
        self.waterLitres = waterLitres
        self.systolicBP = systolicBP
        self.diastolicBP = diastolicBP
        self.steps = steps
    }
}
