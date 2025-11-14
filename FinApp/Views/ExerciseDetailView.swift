//
//  ExerciseDetailView.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//

import SwiftUI
import Charts

struct ExerciseDetailView: View {
    @EnvironmentObject var store: WorkoutStore

    let template: ExerciseTemplate

    // MARK: - Internal models

    private struct HistoryEntry: Identifiable {
        let id = UUID()
        let session: WorkoutSession
        let exercise: Exercise
    }

    private struct HistoryPoint: Identifiable {
        let id = UUID()
        let date: Date
        let topWeight: Double
    }

    // MARK: - Derived data

    private var history: [HistoryEntry] {
        var items: [HistoryEntry] = []

        for session in store.sessions {
            for exercise in session.exercises {
                // Simple match by name
                if exercise.name == template.name {
                    items.append(HistoryEntry(session: session, exercise: exercise))
                }
            }
        }

        // Newest sessions first
        items.sort { $0.session.date > $1.session.date }
        return items
    }

    private var sessionCount: Int {
        var ids = Set<UUID>()
        for entry in history {
            ids.insert(entry.session.id)
        }
        return ids.count
    }

    private var totalSets: Int {
        var count = 0
        for entry in history {
            count += entry.exercise.sets.count
        }
        return count
    }

    private var totalVolume: Int {
        var total: Double = 0
        for entry in history {
            for set in entry.exercise.sets {
                if let weight = set.weight {
                    total += weight * Double(set.reps)
                }
            }
        }
        return Int(total)
    }

    private var lastPerformedDate: Date? {
        history.first?.session.date
    }

    /// Best set across all history, using weight × reps as score.
    private var bestSetSummary: (weight: Double, reps: Int, date: Date)? {
        var bestScore: Double = -Double.infinity
        var bestWeight: Double = 0
        var bestReps: Int = 0
        var bestDate: Date?

        for entry in history {
            for set in entry.exercise.sets {
                let weight = set.weight ?? 0
                let score = weight * Double(set.reps)

                if score > bestScore {
                    bestScore = score
                    bestWeight = weight
                    bestReps = set.reps
                    bestDate = entry.session.date
                }
            }
        }

        if bestScore <= 0 {
            return nil
        }

        if let date = bestDate {
            return (bestWeight, bestReps, date)
        } else {
            return nil
        }
    }

    /// For chart: one point per session with the heaviest set's weight.
    private var historyPoints: [HistoryPoint] {
        var points: [HistoryPoint] = []

        for entry in history {
            var topWeight: Double = 0

            for set in entry.exercise.sets {
                let weight = set.weight ?? 0
                if weight > topWeight {
                    topWeight = weight
                }
            }

            if topWeight > 0 {
                points.append(
                    HistoryPoint(
                        date: entry.session.date,
                        topWeight: topWeight
                    )
                )
            }
        }

        // Oldest first for chart
        points.sort { $0.date < $1.date }
        return points
    }

    // MARK: - Body

    var body: some View {
        List {
            headerSection

            if !historyPoints.isEmpty {
                trendSection
            }

            if history.isEmpty {
                Section {
                    Text("No history yet for this exercise.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                historySection
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text(template.name)
                    .font(.title2.bold())

                Text(template.category)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let last = lastPerformedDate {
                    Text("Last performed: \(last.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not performed yet in logged sessions.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    statBox(title: "Sessions", value: "\(sessionCount)")
                    statBox(title: "Sets", value: "\(totalSets)")
                    statBox(
                        title: "Volume",
                        value: totalVolume > 0 ? "\(totalVolume) kg" : "-"
                    )
                }

                if let best = bestSetSummary {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Best Set")
                            .font(.subheadline.bold())
                        Text("\(best.weight, specifier: "%.1f") kg × \(best.reps) reps")
                            .font(.subheadline)
                        Text(best.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var trendSection: some View {
        Section("Trend") {
            VStack(alignment: .leading, spacing: 8) {
                if let last = historyPoints.last {
                    Text("Top set trend (heaviest set per session)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Chart(historyPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Top Weight", point.topWeight)
                        )
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Top Weight", point.topWeight)
                        )
                    }
                    .frame(height: 180)

                    Text("Latest top set: \(last.topWeight, specifier: "%.1f") kg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var historySection: some View {
        Section("History") {
            ForEach(history) { entry in
                NavigationLink {
                    WorkoutSessionDetailView(sessionID: entry.session.id)
                } label: {
                    historyRow(for: entry)
                }
            }
        }
    }

    // MARK: - Rows / helpers

    private func historyRow(for entry: HistoryEntry) -> some View {
        let dateText = entry.session.date.formatted(date: .abbreviated, time: .shortened)

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateText)
                    .font(.subheadline)
                Text(entry.session.title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.exercise.sets.count) sets")
                    .font(.caption)

                if let topSet = bestSet(in: entry.exercise) {
                    Text("\(topSet.weight, specifier: "%.0f") kg × \(topSet.reps)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func statBox(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bestSet(in exercise: Exercise) -> (weight: Double, reps: Int)? {
        var bestScore: Double = -Double.infinity
        var bestWeight: Double = 0
        var bestReps: Int = 0

        for set in exercise.sets {
            let weight = set.weight ?? 0
            let score = weight * Double(set.reps)

            if score > bestScore {
                bestScore = score
                bestWeight = weight
                bestReps = set.reps
            }
        }

        if bestScore <= 0 {
            return nil
        }

        return (bestWeight, bestReps)
    }
}
