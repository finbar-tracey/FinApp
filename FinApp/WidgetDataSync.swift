//
//  WidgetDataSync.swift
//  FinApp
//
//  Created by Finbar Tracey on 13/11/2025.
//

import Foundation
import WidgetKit

enum WidgetDataSync {
    private static let appGroupID = "group.com.Finbar.FinApp"

    private enum Keys {
        static let stepsToday   = "steps_today"
        static let sleepHours   = "sleep_hours"
        static let restingHR    = "resting_hr"
        static let weight       = "weight_kg"
        static let lastSyncDate = "last_sync"
    }

    static func save(
        steps: Int,
        sleepHours: Double,
        restingHR: Int?,
        weight: Double?
    ) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            print("⚠️ WidgetDataSync: could not get UserDefaults for app group")
            return
        }

        defaults.set(steps, forKey: Keys.stepsToday)
        defaults.set(sleepHours, forKey: Keys.sleepHours)

        if let restingHR {
            defaults.set(restingHR, forKey: Keys.restingHR)
        }

        if let weight {
            defaults.set(weight, forKey: Keys.weight)
        }

        defaults.set(Date(), forKey: Keys.lastSyncDate)

        print("✅ WidgetDataSync: saved steps=\(steps), sleep=\(sleepHours), rhr=\(restingHR ?? -1), weight=\(weight ?? -1)")

        WidgetCenter.shared.reloadAllTimelines()
        // or: WidgetCenter.shared.reloadTimelines(ofKind: "FinAppDashboardWidget")
    }
}
