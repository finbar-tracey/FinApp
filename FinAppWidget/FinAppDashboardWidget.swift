//
//  FinAppDashboardWidget.swift
//  FinApp
//
//  Created by Finbar Tracey on 13/11/2025.
//

import WidgetKit
import SwiftUI

// MARK: - Shared constants

private let appGroupID = "group.com.Finbar.FinApp"
private let widgetKind = "FinAppDashboardWidget"

// Keys used in shared UserDefaults
private enum SharedKeys {
    static let stepsToday   = "steps_today"
    static let sleepHours   = "sleep_hours"
    static let restingHR    = "resting_hr"
    static let weight       = "weight_kg"
    static let lastSyncDate = "last_sync"
}

// MARK: - Entry

struct DashboardEntry: TimelineEntry {
    let date: Date
    let steps: Int
    let sleepHours: Double
    let restingHR: Int
    let weight: Double
    let lastSync: Date?
}

// MARK: - Timeline Provider

struct DashboardProvider: TimelineProvider {

    func placeholder(in context: Context) -> DashboardEntry {
        DashboardEntry(
            date: Date(),
            steps: 4567,
            sleepHours: 6.8,
            restingHR: 52,
            weight: 78.4,
            lastSync: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DashboardEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DashboardEntry>) -> Void) {
        let entry = loadEntry()

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Load from shared UserDefaults

    private func loadEntry() -> DashboardEntry {
        let defaults = UserDefaults(suiteName: appGroupID)

        let steps      = defaults?.integer(forKey: SharedKeys.stepsToday) ?? 0
        let sleepHours = defaults?.double(forKey: SharedKeys.sleepHours) ?? 0
        let restingHR  = defaults?.integer(forKey: SharedKeys.restingHR) ?? 0
        let weight     = defaults?.double(forKey: SharedKeys.weight) ?? 0
        let lastSync   = defaults?.object(forKey: SharedKeys.lastSyncDate) as? Date

        print("📦 Widget loadEntry from \(appGroupID): defaults=\(String(describing: defaults)), steps=\(steps), sleep=\(sleepHours), rhr=\(restingHR), weight=\(weight), lastSync=\(String(describing: lastSync))")

        return DashboardEntry(
            date: Date(),
            steps: steps,
            sleepHours: sleepHours,
            restingHR: restingHR,
            weight: weight,
            lastSync: lastSync
        )
    }

}

// MARK: - Root Widget View

struct FinAppDashboardWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: DashboardEntry

    var body: some View {
            Group {
                switch family {
                case .systemSmall:
                    SmallDashboardView(entry: entry)
                case .systemMedium:
                    MediumDashboardView(entry: entry)
                case .accessoryCircular:
                    AccessoryCircularDashboardView(entry: entry)
                case .accessoryRectangular:
                    AccessoryRectangularDashboardView(entry: entry)
                case .accessoryInline:
                    AccessoryInlineDashboardView(entry: entry)
                default:
                    SmallDashboardView(entry: entry)
                }
            }
            .containerBackground(for: .widget) {
                // Let the system give it a nice, automatic background
                Color.clear
            }
        }
}

// MARK: - Small Widget View

struct SmallDashboardView: View {
    let entry: DashboardEntry

    var body: some View {
        VStack(spacing: 6) {
            let progress = min(Double(entry.steps) / 10_000.0, 1.0)

            ProgressView(value: progress) {
                Text("Steps")
                    .font(.caption2)
            }
            .progressViewStyle(.circular)

            Text("\(entry.steps)")
                .font(.headline)
                .minimumScaleFactor(0.6)

            if let lastSync = entry.lastSync {
                Text(lastSync, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Medium Widget View

struct MediumDashboardView: View {
    let entry: DashboardEntry

    var body: some View {
        HStack {
            VStack(spacing: 12) {
                let stepsProgress = min(Double(entry.steps) / 10_000.0, 1.0)
                VStack(spacing: 4) {
                    ProgressView(value: stepsProgress) {
                        Text("Steps")
                            .font(.caption2)
                    }
                    .progressViewStyle(.circular)

                    Text("\(entry.steps)")
                        .font(.subheadline)
                        .minimumScaleFactor(0.7)
                }

                let sleepProgress = min(entry.sleepHours / 8.0, 1.0)
                VStack(spacing: 4) {
                    ProgressView(value: sleepProgress) {
                        Text("Sleep")
                            .font(.caption2)
                    }
                    .progressViewStyle(.circular)

                    Text("\(entry.sleepHours, specifier: "%.1f") h")
                        .font(.subheadline)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.headline)

                Text("Steps: \(entry.steps)")
                Text("Sleep: \(entry.sleepHours, specifier: "%.1f") h")

                if entry.restingHR > 0 {
                    Text("RHR: \(entry.restingHR) bpm")
                }

                if entry.weight > 0 {
                    Text("Weight: \(entry.weight, specifier: "%.1f") kg")
                }

                if let lastSync = entry.lastSync {
                    Text("Synced: \(lastSync, style: .time)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
        }
        .padding()
    }
}

// MARK: - Lock Screen: Circular

struct AccessoryCircularDashboardView: View {
    let entry: DashboardEntry

    var body: some View {
        let progress = min(Double(entry.steps) / 10_000.0, 1.0)

        ZStack {
            ProgressView(value: progress)
                .progressViewStyle(.circular)
            Text("\(entry.steps)")
                .font(.system(size: 10, weight: .semibold))
                .minimumScaleFactor(0.5)
        }
    }
}

// MARK: - Lock Screen: Rectangular

struct AccessoryRectangularDashboardView: View {
    let entry: DashboardEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("FinApp")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Steps: \(entry.steps)")
                .font(.caption2)

            Text("Sleep: \(entry.sleepHours, specifier: "%.1f") h")
                .font(.caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Lock Screen: Inline

struct AccessoryInlineDashboardView: View {
    let entry: DashboardEntry

    var body: some View {
        Text("Steps \(entry.steps) · RHR \(entry.restingHR)bpm")
    }
}

// MARK: - Widget Configuration

struct FinAppDashboardWidget: Widget {
    let kind: String = widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DashboardProvider()) { entry in
            FinAppDashboardWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FinApp Dashboard")
        .description("View today’s key health stats at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Preview

struct FinAppDashboardWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sample = DashboardEntry(
            date: Date(),
            steps: 7423,
            sleepHours: 7.1,
            restingHR: 51,
            weight: 78.3,
            lastSync: Date()
        )

        Group {
            FinAppDashboardWidgetEntryView(entry: sample)
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            FinAppDashboardWidgetEntryView(entry: sample)
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            FinAppDashboardWidgetEntryView(entry: sample)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))

            FinAppDashboardWidgetEntryView(entry: sample)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))

            FinAppDashboardWidgetEntryView(entry: sample)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
        }
    }
}
