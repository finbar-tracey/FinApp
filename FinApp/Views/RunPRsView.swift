//
//  RunPRsView.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//

import SwiftUI

struct RunPRsView: View {
    @EnvironmentObject var cardio: CardioStore

    private var runs: [CardioEntry] {
        cardio.entries.filter {
            $0.type == .run &&
            ($0.distanceKm ?? 0) > 0 &&
            $0.durationMinutes > 0
        }
    }

    struct DistancePR {
        let distanceKm: Double
        let estimatedMinutes: Double
        let paceMinutesPerKm: Double
        let entry: CardioEntry
    }

    private var pr1k: DistancePR?        { bestPR(for: 1.0) }
    private var pr5k: DistancePR?        { bestPR(for: 5.0) }
    private var pr10k: DistancePR?       { bestPR(for: 10.0) }
    private var prHalf: DistancePR?      { bestPR(for: 21.1) }

    private var longestRun: CardioEntry? {
        runs.max { (a, b) in
            (a.distanceKm ?? 0) < (b.distanceKm ?? 0)
        }
    }

    private var fastestPaceRun: CardioEntry? {
        runs.min { (a, b) in
            (a.paceMinutesPerKm ?? .infinity) <
            (b.paceMinutesPerKm ?? .infinity)
        }
    }

    var body: some View {
        List {
            if runs.isEmpty {
                Section {
                    Text("No running data yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                distanceSection
                specialSection
            }
        }
        .navigationTitle("Running PRs")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var distanceSection: some View {
        Section("Distance PRs (estimated from avg pace)") {
            prRow(label: "1 km", pr: pr1k)
            prRow(label: "5 km", pr: pr5k)
            prRow(label: "10 km", pr: pr10k)
            prRow(label: "Half marathon", pr: prHalf)
        }
    }

    private var specialSection: some View {
        Section("Highlights") {
            if let longest = longestRun {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Longest run")
                        .font(.subheadline.bold())
                    HStack {
                        if let dist = longest.distanceKm {
                            Text("\(dist, specifier: "%.2f") km")
                        }
                        Text("· \(longest.durationMinutes) min")
                    }
                    .font(.subheadline)
                    if let pace = longest.paceMinutesPerKm {
                        Text("Avg pace: \(paceString(from: pace)) /km")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(longest.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            if let fastest = fastestPaceRun,
               let pace = fastest.paceMinutesPerKm {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fastest avg pace")
                        .font(.subheadline.bold())
                    HStack {
                        if let dist = fastest.distanceKm {
                            Text("\(dist, specifier: "%.2f") km")
                        }
                        Text("· \(fastest.durationMinutes) min")
                    }
                    .font(.subheadline)
                    Text("\(paceString(from: pace)) /km")
                        .font(.subheadline)
                    Text(fastest.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Rows / helpers

    private func prRow(label: String, pr: DistancePR?) -> some View {
        HStack {
            Text(label)
            Spacer()
            if let pr {
                Text(timeString(from: pr.estimatedMinutes))
                    .font(.body)
                if pr.paceMinutesPerKm.isFinite {
                    Text("· \(paceString(from: pr.paceMinutesPerKm)) /km")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("—")
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Best (fastest) estimated time for target distance, using avg pace from whole run.
    private func bestPR(for targetKm: Double) -> DistancePR? {
        let candidates = runs.filter { ($0.distanceKm ?? 0) >= targetKm }
        guard !candidates.isEmpty else { return nil }

        var best: DistancePR?
        for entry in candidates {
            guard let dist = entry.distanceKm,
                  dist > 0 else { continue }

            let pace = Double(entry.durationMinutes) / dist
            let estimatedMinutes = pace * targetKm

            if let current = best {
                if estimatedMinutes < current.estimatedMinutes {
                    best = DistancePR(
                        distanceKm: targetKm,
                        estimatedMinutes: estimatedMinutes,
                        paceMinutesPerKm: pace,
                        entry: entry
                    )
                }
            } else {
                best = DistancePR(
                    distanceKm: targetKm,
                    estimatedMinutes: estimatedMinutes,
                    paceMinutesPerKm: pace,
                    entry: entry
                )
            }
        }
        return best
    }

    private func timeString(from minutes: Double) -> String {
        if minutes.isNaN || minutes.isInfinite { return "-" }
        let totalSeconds = Int(minutes * 60)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func paceString(from minutesPerKm: Double) -> String {
        if minutesPerKm.isNaN || minutesPerKm.isInfinite { return "-" }
        let totalSeconds = Int(minutesPerKm * 60)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
