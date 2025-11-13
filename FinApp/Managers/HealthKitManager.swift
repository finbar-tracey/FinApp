//
//  HealthKitManager.swift
//  FinApp
//
//  Created by Finbar Tracey on 11/11/2025.
//  Updated by Finbar Tracey on 12/11/2025.
//
import Foundation
import HealthKit
import Combine

// Public model for UI
public struct SleepBreakdown {
    public let remSeconds: TimeInterval
    public let deepSeconds: TimeInterval
    public let coreSeconds: TimeInterval
    public let unspecifiedSeconds: TimeInterval
    public let totalSeconds: TimeInterval

    public var remPct: Double           { totalSeconds > 0 ? remSeconds / totalSeconds : 0 }
    public var deepPct: Double          { totalSeconds > 0 ? deepSeconds / totalSeconds : 0 }
    public var corePct: Double          { totalSeconds > 0 ? coreSeconds / totalSeconds : 0 }
    public var unspecifiedPct: Double   { totalSeconds > 0 ? unspecifiedSeconds / totalSeconds : 0 }

    public var remHours: Double         { remSeconds / 3600 }
    public var deepHours: Double        { deepSeconds / 3600 }
    public var coreHours: Double        { coreSeconds / 3600 }
    public var unspecifiedHours: Double { unspecifiedSeconds / 3600 }
    public var totalHours: Double       { totalSeconds / 3600 }
}

final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    // What we’ll read
    private let weightType     = HKObjectType.quantityType(forIdentifier: .bodyMass)!
    private let restingHRType  = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
    private let sleepType      = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let stepType       = HKObjectType.quantityType(forIdentifier: .stepCount)!

    @Published private(set) var isAvailable = HKHealthStore.isHealthDataAvailable()
    @Published private(set) var isAuthorized = false

    // MARK: - Permissions

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let toShare: Set<HKSampleType> = [] // read-only for now
        let toRead:  Set<HKObjectType> = [weightType, restingHRType, sleepType, stepType]

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
            let kg = sample?.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
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

    func stepsToday(completion: @escaping (Int?) -> Void) {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay,
                                                    end: Date(),
                                                    options: [.strictStartDate, .strictEndDate])

        let query = HKStatisticsQuery(quantityType: stepType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, stats, _ in
            let total = stats?.sumQuantity()?.doubleValue(for: HKUnit.count())
            DispatchQueue.main.async { completion(total.map { Int($0) }) }
        }
        store.execute(query)
    }

    // MARK: - Sleep (overlap-safe + stage breakdowns)

    /// Total sleep (hours) for "last night" using a stable noon-anchored window:
    /// Window = yesterday 12:00 → today 12:00.
    /// - Keeps only asleep categories (excludes `.inBed`)
    /// - Merges overlapping intervals across sources (Watch, iPhone, apps)
    func lastNightSleepHours(completion: @escaping (Double?) -> Void) {
        let (start, end) = anchoredNoonWindowEndingToday()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end,
                                                    options: [.strictStartDate, .strictEndDate])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let q = HKSampleQuery(sampleType: sleepType,
                              predicate: predicate,
                              limit: HKObjectQueryNoLimit,
                              sortDescriptors: [sort]) { _, results, _ in
            let samples = (results as? [HKCategorySample]) ?? []

            let asleepIntervals = Self.asleepIntervals(from: samples)
            let merged = Self.mergeIntervals(asleepIntervals)

            let totalSeconds = Self.sumSeconds(merged)
            let hours = totalSeconds / 3600.0

            DispatchQueue.main.async { completion(hours > 0 ? hours : nil) }
        }
        store.execute(q)
    }

    /// Stage breakdown (REM/Deep/Core/Unspecified) with optional single-source preference.
    /// Total is computed as the union across stages to avoid >100%.
    func lastNightSleepBreakdown(preferSourceBundleId: String? = nil,
                                 completion: @escaping (SleepBreakdown?) -> Void) {
        let (start, end) = anchoredNoonWindowEndingToday()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end,
                                                    options: [.strictStartDate, .strictEndDate])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let q = HKSampleQuery(sampleType: sleepType,
                              predicate: predicate,
                              limit: HKObjectQueryNoLimit,
                              sortDescriptors: [sort]) { _, results, _ in
            let all = (results as? [HKCategorySample]) ?? []

            let samples: [HKCategorySample]
            if let bundle = preferSourceBundleId {
                samples = all.filter { $0.sourceRevision.source.bundleIdentifier == bundle }
            } else {
                samples = all
            }

            // Stage intervals (merged per stage)
            let remM      = Self.mergeIntervals(Self.stageIntervals(from: samples, stage: .rem))
            let deepM     = Self.mergeIntervals(Self.stageIntervals(from: samples, stage: .deep))
            let coreM     = Self.mergeIntervals(Self.stageIntervals(from: samples, stage: .core))
            let unspecM   = Self.mergeIntervals(Self.stageIntervals(from: samples, stage: .unspecified))

            // Totals per stage
            let remSec    = Self.sumSeconds(remM)
            let deepSec   = Self.sumSeconds(deepM)
            let coreSec   = Self.sumSeconds(coreM)
            let unspecSec = Self.sumSeconds(unspecM)

            // Total = union of all asleep intervals (keeps total correct)
            let unionAll  = Self.mergeIntervals(remM + deepM + coreM + unspecM)
            let totalSec  = Self.sumSeconds(unionAll)

            let breakdown = SleepBreakdown(remSeconds: remSec,
                                           deepSeconds: deepSec,
                                           coreSeconds: coreSec,
                                           unspecifiedSeconds: unspecSec,
                                           totalSeconds: totalSec)

            DispatchQueue.main.async { completion(totalSec > 0 ? breakdown : nil) }
        }
        store.execute(q)
    }

    /// Mutually exclusive stage breakdown (no overlaps; sums to 100% of "asleep" time).
    /// Priority: Deep > REM > Core > Unspecified.
    func lastNightExclusiveSleepBreakdown(completion: @escaping (SleepBreakdown?) -> Void) {
        let (start, end) = anchoredNoonWindowEndingToday()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end,
                                                    options: [.strictStartDate, .strictEndDate])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let q = HKSampleQuery(sampleType: sleepType,
                              predicate: predicate,
                              limit: HKObjectQueryNoLimit,
                              sortDescriptors: [sort]) { _, results, _ in
            let all = (results as? [HKCategorySample]) ?? []

            let remM     = Self.mergeIntervals(Self.stageIntervals(from: all, stage: .rem))
            let deepM    = Self.mergeIntervals(Self.stageIntervals(from: all, stage: .deep))
            let coreM    = Self.mergeIntervals(Self.stageIntervals(from: all, stage: .core))
            let unspecM  = Self.mergeIntervals(Self.stageIntervals(from: all, stage: .unspecified))

            let boundaries = Set((remM + deepM + coreM + unspecM).flatMap { [$0.start, $0.end] }).sorted()

            var remSec: TimeInterval = 0, deepSec: TimeInterval = 0, coreSec: TimeInterval = 0, unspecSec: TimeInterval = 0
            for i in 0..<(boundaries.count - 1) {
                let a = boundaries[i], b = boundaries[i+1]
                guard a < b else { continue }
                let inDeep  = Self.interval(a,b, overlapsAnyOf: deepM)
                let inREM   = Self.interval(a,b, overlapsAnyOf: remM)
                let inCore  = Self.interval(a,b, overlapsAnyOf: coreM)
                let inUnsp  = Self.interval(a,b, overlapsAnyOf: unspecM)
                let slice = b.timeIntervalSince(a)
                if inDeep      { deepSec  += slice }
                else if inREM  { remSec   += slice }
                else if inCore { coreSec  += slice }
                else if inUnsp { unspecSec += slice }
            }

            let totalSec = remSec + deepSec + coreSec + unspecSec
            let breakdown = SleepBreakdown(remSeconds: remSec,
                                           deepSeconds: deepSec,
                                           coreSeconds: coreSec,
                                           unspecifiedSeconds: unspecSec,
                                           totalSeconds: totalSec)
            DispatchQueue.main.async { completion(totalSec > 0 ? breakdown : nil) }
        }
        store.execute(q)
    }

    // MARK: - Preferred source detection (auto-pick Garmin if present)

    /// Detects a preferred sleep source for last night.
    /// Priority: Garmin (bundle contains "garmin") > Apple/Watch (bundle contains "watch" or starts with "com.apple") > nil
    func detectPreferredSleepSourceBundleId(completion: @escaping (String?) -> Void) {
        let (start, end) = anchoredNoonWindowEndingToday()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let q = HKSampleQuery(sampleType: sleepType,
                              predicate: predicate,
                              limit: HKObjectQueryNoLimit,
                              sortDescriptors: [sort]) { _, results, _ in
            let samples = (results as? [HKCategorySample]) ?? []
            let bundles = Set(samples.map { $0.sourceRevision.source.bundleIdentifier })

            // Prefer Garmin if present
            if let garmin = bundles.first(where: { $0.lowercased().contains("garmin") }) {
                DispatchQueue.main.async { completion(garmin) }
                return
            }
            // Else prefer Apple/Watch
            if let appleWatch = bundles.first(where: { $0.lowercased().contains("watch") || $0.hasPrefix("com.apple") }) {
                DispatchQueue.main.async { completion(appleWatch) }
                return
            }
            DispatchQueue.main.async { completion(nil) }
        }
        store.execute(q)
    }

    // MARK: - Convenience: pull into your HealthStore

    /// Reads latest weight, resting HR, steps today, and last night's sleep; then upserts a HealthEntry for today.
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
            let cal = Calendar.current
            let startOfToday = cal.startOfDay(for: Date())

            if let idx = healthStore.entries.firstIndex(where: { $0.date >= startOfToday }) {
                var e = healthStore.entries[idx]
                if let w = weightKg    { e.weightKg = w }
                if let h = sleepH      { e.sleepHours = h }
                if let r = rhr         { e.restingHeartRate = r }
                if let s = stepsCount  { e.steps = s }
                healthStore.update(e)
            } else {
                var e = HealthEntry(date: Date())
                e.weightKg = weightKg
                e.sleepHours = sleepH
                e.restingHeartRate = rhr
                e.steps = stepsCount
                healthStore.add(e)
            }
            
            let safeSteps = stepsCount ?? 0
            let safeSleep = sleepH ?? 0

            WidgetDataSync.save(
                steps: safeSteps,
                sleepHours: safeSleep,
                restingHR: rhr,
                weight: weightKg
            )
            
            completion(nil)
        }
    }

    // MARK: - Helpers

    private enum SleepStage { case rem, deep, core, unspecified }

    private static func asleepIntervals(from samples: [HKCategorySample]) -> [(start: Date, end: Date)] {
        let wanted: Set<Int>
        if #available(iOS 16.0, *) {
            wanted = Set([
                HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                HKCategoryValueSleepAnalysis.asleepREM.rawValue
            ])
        } else {
            wanted = Set([HKCategoryValueSleepAnalysis.asleep.rawValue])
        }
        return samples.compactMap { s in
            wanted.contains(s.value) ? (start: s.startDate, end: s.endDate) : nil
        }
    }

    private static func stageIntervals(from samples: [HKCategorySample],
                                       stage: SleepStage) -> [(start: Date, end: Date)] {
        let wanted: Set<Int>
        if #available(iOS 16.0, *) {
            switch stage {
            case .rem:         wanted = [HKCategoryValueSleepAnalysis.asleepREM.rawValue]
            case .deep:        wanted = [HKCategoryValueSleepAnalysis.asleepDeep.rawValue]
            case .core:        wanted = [HKCategoryValueSleepAnalysis.asleepCore.rawValue]
            case .unspecified: wanted = [HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue]
            }
        } else {
            switch stage {
            case .unspecified: wanted = [HKCategoryValueSleepAnalysis.asleep.rawValue]
            default:           wanted = []
            }
        }
        return samples.compactMap { s in
            wanted.contains(s.value) ? (start: s.startDate, end: s.endDate) : nil
        }
    }

    /// Merge overlapping or touching intervals to avoid double counting.
    private static func mergeIntervals(_ intervals: [(start: Date, end: Date)]) -> [(start: Date, end: Date)] {
        guard !intervals.isEmpty else { return [] }
        let sorted = intervals.sorted { $0.start < $1.start }
        var merged: [(start: Date, end: Date)] = []
        var current = sorted[0]

        for next in sorted.dropFirst() {
            if next.start <= current.end {
                if next.end > current.end { current.end = next.end }
            } else {
                merged.append(current)
                current = next
            }
        }
        merged.append(current)
        return merged
    }

    private static func sumSeconds(_ intervals: [(start: Date, end: Date)]) -> TimeInterval {
        intervals.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) }
    }

    private static func interval(_ a: Date, _ b: Date,
                                 overlapsAnyOf intervals: [(start: Date, end: Date)]) -> Bool {
        intervals.contains { a < $0.end && b > $0.start }
    }

    /// Yesterday 12:00 → Today 12:00 (captures one full "night" even if it spans midnight).
    private func anchoredNoonWindowEndingToday() -> (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.year, .month, .day], from: now)
        comps.hour = 12; comps.minute = 0; comps.second = 0
        let todayNoon = cal.date(from: comps)!
        let start = cal.date(byAdding: .day, value: -1, to: todayNoon)!  // yesterday noon
        let end = todayNoon                                              // today noon
        return (start, end)
    }

    // MARK: - Debug

    /// Prints raw sleep samples and sources for last night to the console.
    func debugPrintLastNightSleepSamples() {
        let (start, end) = anchoredNoonWindowEndingToday()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let q = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, results, _ in
            let samples = (results as? [HKCategorySample]) ?? []
            for s in samples {
                let src = s.sourceRevision.source
                print("Sleep sample \(s.startDate)–\(s.endDate) value=\(s.value) source=\(src.name) (\(src.bundleIdentifier))")
            }
        }
        store.execute(q)
    }
}
