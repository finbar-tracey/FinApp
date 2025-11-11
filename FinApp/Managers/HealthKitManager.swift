//
//  HealthKitManager.swift
//  FinApp
//
//  Created by Finbar Tracey on 11/11/2025.
//
import Foundation
import HealthKit
import Combine

final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    // What we’ll read
    private let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
    private let restingHRType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!

    @Published private(set) var isAvailable = HKHealthStore.isHealthDataAvailable()
    @Published private(set) var isAuthorized = false

    // MARK: - Permissions

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let toShare: Set<HKSampleType> = [] // read-only for now
        let toRead: Set<HKObjectType> = [weightType, restingHRType, sleepType, stepType]

        store.requestAuthorization(toShare: toShare, read: toRead) { [weak self] success, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                completion(success)
            }
        }
    }

    // MARK: - Fetchers (most-recent / today)

    func mostRecentWeightKg(completion: @escaping (Double?) -> Void) {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let q = HKSampleQuery(sampleType: weightType,
                              predicate: nil,
                              limit: 1,
                              sortDescriptors: [sort]) { _, samples, _ in
            let sample = samples?.first as? HKQuantitySample
            let kg = sample?.quantity.doubleValue(for: .gramUnit(with: .kilo))
            DispatchQueue.main.async { completion(kg) }
        }
        store.execute(q)
    }

    func mostRecentRestingHR(completion: @escaping (Int?) -> Void) {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let q = HKSampleQuery(sampleType: restingHRType,
                              predicate: nil,
                              limit: 1,
                              sortDescriptors: [sort]) { _, samples, _ in
            let sample = samples?.first as? HKQuantitySample
            let bpm = sample?.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            DispatchQueue.main.async { completion(bpm.map { Int(round($0)) }) }
        }
        store.execute(q)
    }
    
    //
    func stepsToday(completion: @escaping (Int?) -> Void) {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, stats, _ in
            let total = stats?.sumQuantity()?.doubleValue(for: HKUnit.count())
            DispatchQueue.main.async { completion(total.map { Int($0) }) }
        }
        store.execute(query)
    }

    /// Total sleep (hours) for "last night" (8pm yesterday -> 12pm today), summing asleep segments.
    func lastNightSleepHours(completion: @escaping (Double?) -> Void) {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(bySettingHour: 20, minute: 0, second: 0, of: cal.date(byAdding: .day, value: -1, to: now)!)!
        let end   = cal.date(bySettingHour: 12, minute: 0, second: 0, of: now)!

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let q = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
            let asleepValues: [HKCategoryValueSleepAnalysis] = [
                .asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM
            ]

            let totalSeconds: TimeInterval = (samples as? [HKCategorySample])?
                .filter { sample in asleepValues.contains(HKCategoryValueSleepAnalysis(rawValue: sample.value) ?? .inBed) }
                .reduce(0) { acc, s in acc + s.endDate.timeIntervalSince(s.startDate) } ?? 0

            let hours = totalSeconds / 3600.0
            DispatchQueue.main.async { completion(hours > 0 ? hours : nil) }
        }
        store.execute(q)
    }

    // MARK: - Convenience: pull into your HealthStore

    /// Reads latest weight, resting HR, and last night's sleep, then upserts a HealthEntry for today.
    func syncToday(into healthStore: HealthStore, completion: @escaping (Error?) -> Void) {
        let group = DispatchGroup()

        var weightKg: Double?
        var rhr: Int?
        var sleepH: Double?
        var stepsCount: Int?

        group.enter()
        stepsToday { v in stepsCount = v; group.leave() }

        group.enter()
        mostRecentWeightKg { v in weightKg = v; group.leave() }

        group.enter()
        mostRecentRestingHR { v in rhr = v; group.leave() }

        group.enter()
        lastNightSleepHours { v in sleepH = v; group.leave() }

        group.notify(queue: .main) {
            // Upsert today’s entry
            let cal = Calendar.current
            let startOfToday = cal.startOfDay(for: Date())
            if let idx = healthStore.entries.firstIndex(where: { $0.date >= startOfToday }) {
                var e = healthStore.entries[idx]
                if let w = weightKg { e.weightKg = w }
                if let h = sleepH   { e.sleepHours = h }
                if let r = rhr      { e.restingHeartRate = r }
                if let s = stepsCount { e.steps = s }
                healthStore.update(e)
            } else {
                var e = HealthEntry(date: Date())
                e.weightKg = weightKg
                e.sleepHours = sleepH
                e.restingHeartRate = rhr
                e.steps = stepsCount
                healthStore.add(e)
            }
            completion(nil)
        }
    }
}
