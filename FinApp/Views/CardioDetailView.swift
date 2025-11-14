//
//  CardioDetailView.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//
import SwiftUI

struct CardioDetailView: View {
    @EnvironmentObject var cardio: CardioStore

    let entry: CardioEntry

    // MARK: - PR model

    private struct DistancePR {
        let distanceKm: Double
        let estimatedMinutes: Double
        let paceMinutesPerKm: Double
        let entry: CardioEntry
    }

    private struct PRBadge: Identifiable {
        let id = UUID()
        let label: String
    }

    // MARK: - Helpers: runs + PRs

    private var runs: [CardioEntry] {
        cardio.entries.filter {
            $0.type == .run &&
            ($0.distanceKm ?? 0) > 0 &&
            $0.durationMinutes > 0
        }
    }

    private var pr1k: DistancePR?   { bestPR(for: 1.0) }
    private var pr5k: DistancePR?   { bestPR(for: 5.0) }
    private var pr10k: DistancePR?  { bestPR(for: 10.0) }
    private var prHalf: DistancePR? { bestPR(for: 21.1) }

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

    /// All PR badges that apply to this entry.
    private var prBadges: [PRBadge] {
        guard entry.type == .run,
              let distance = entry.distanceKm,
              distance > 0,
              entry.durationMinutes > 0 else {
            return []
        }

        var badges: [PRBadge] = []

        if let pr1k, pr1k.entry.id == entry.id {
            badges.append(PRBadge(label: "1K PR"))
        }
        if let pr5k, pr5k.entry.id == entry.id {
            badges.append(PRBadge(label: "5K PR"))
        }
        if let pr10k, pr10k.entry.id == entry.id {
            badges.append(PRBadge(label: "10K PR"))
        }
        if let prHalf, prHalf.entry.id == entry.id {
            badges.append(PRBadge(label: "Half PR"))
        }
        if let longestRun, longestRun.id == entry.id {
            badges.append(PRBadge(label: "Longest run"))
        }
        if let fastestPaceRun,
           fastestPaceRun.id == entry.id,
           entry.paceMinutesPerKm != nil {
            badges.append(PRBadge(label: "Fastest pace"))
        }

        return badges
    }

    // MARK: - Basic display strings

    private var dateString: String {
        entry.date.formatted(date: .complete, time: .shortened)
    }

    private var mainLine: String {
        if let distance = entry.distanceKm {
            let formattedDistance = String(format: "%.2f", distance)
            return "\(formattedDistance) km in \(entry.durationMinutes) min"
        } else {
            return "\(entry.durationMinutes) min"
        }
    }

    private var paceString: String? {
        guard let pace = entry.paceMinutesPerKm else { return nil }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    // MARK: - Body

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // Title + type
                    Text(entry.type.rawValue)
                        .font(.title2.bold())

                    Text(dateString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // PR badges row (if any)
                    if !prBadges.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(prBadges) { badge in
                                    Text(badge.label)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.15))
                                        .foregroundStyle(Color.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Main stats
                    Text(mainLine)
                        .font(.headline)

                    if let paceString {
                        Text("Pace: \(paceString)")
                            .font(.subheadline)
                    }

                    if let hr = entry.avgHeartRate {
                        Text("Avg HR: \(hr) bpm")
                            .font(.subheadline)
                    }
                }
                .padding(.vertical, 4)
            }

            if let notes = entry.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }
        }
        .navigationTitle("Cardio")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - PR helpers

    /// Best (fastest) estimated time for target distance, using avg pace from whole run.
    private func bestPR(for targetKm: Double) -> DistancePR? {
        let candidates = runs.filter { ($0.distanceKm ?? 0) >= targetKm }
        guard !candidates.isEmpty else { return nil }

        var best: DistancePR?

        for candidate in candidates {
            guard let dist = candidate.distanceKm, dist > 0 else { continue }

            let pace = Double(candidate.durationMinutes) / dist
            let estimatedMinutes = pace * targetKm

            if let current = best {
                if estimatedMinutes < current.estimatedMinutes {
                    best = DistancePR(
                        distanceKm: targetKm,
                        estimatedMinutes: estimatedMinutes,
                        paceMinutesPerKm: pace,
                        entry: candidate
                    )
                }
            } else {
                best = DistancePR(
                    distanceKm: targetKm,
                    estimatedMinutes: estimatedMinutes,
                    paceMinutesPerKm: pace,
                    entry: candidate
                )
            }
        }

        return best
    }
}
