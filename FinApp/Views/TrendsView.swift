import SwiftUI
import Charts

struct TrendsView: View {
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var cardio: CardioStore

    // MARK: - Internal models

    private struct WorkoutWeekSummary: Identifiable {
        let id = UUID()
        let weekStart: Date
        let sessionCount: Int
        let totalSets: Int
        let totalVolume: Double
    }

    private struct CardioWeekSummary: Identifiable {
        let id = UUID()
        let weekStart: Date
        let sessionCount: Int
        let totalDistanceKm: Double
        let totalMinutes: Int
    }

    // MARK: - Derived data

    private var workoutWeekSummaries: [WorkoutWeekSummary] {
        let calendar = Calendar.current
        var buckets: [Date: (sessions: [WorkoutSession], sets: Int, volume: Double)] = [:]

        for session in store.sessions {
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: session.date)?.start else {
                continue
            }

            var bucket = buckets[weekStart] ?? (sessions: [], sets: 0, volume: 0)

            bucket.sessions.append(session)

            var sessionSets = 0
            var sessionVolume: Double = 0

            for exercise in session.exercises {
                for set in exercise.sets {
                    sessionSets += 1
                    if let weight = set.weight {
                        sessionVolume += weight * Double(set.reps)
                    }
                }
            }

            bucket.sets += sessionSets
            bucket.volume += sessionVolume

            buckets[weekStart] = bucket
        }

        var summaries: [WorkoutWeekSummary] = []
        for (weekStart, bucket) in buckets {
            summaries.append(
                WorkoutWeekSummary(
                    weekStart: weekStart,
                    sessionCount: bucket.sessions.count,
                    totalSets: bucket.sets,
                    totalVolume: bucket.volume
                )
            )
        }

        summaries.sort { $0.weekStart < $1.weekStart }
        return summaries
    }

    private var cardioWeekSummaries: [CardioWeekSummary] {
        let calendar = Calendar.current
        var buckets: [Date: (entries: [CardioEntry], distance: Double, minutes: Int)] = [:]

        for entry in cardio.entries {
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: entry.date)?.start else {
                continue
            }

            var bucket = buckets[weekStart] ?? (entries: [], distance: 0, minutes: 0)

            bucket.entries.append(entry)
            bucket.minutes += entry.durationMinutes
            if let dist = entry.distanceKm {
                bucket.distance += dist
            }

            buckets[weekStart] = bucket
        }

        var summaries: [CardioWeekSummary] = []
        for (weekStart, bucket) in buckets {
            summaries.append(
                CardioWeekSummary(
                    weekStart: weekStart,
                    sessionCount: bucket.entries.count,
                    totalDistanceKm: bucket.distance,
                    totalMinutes: bucket.minutes
                )
            )
        }

        summaries.sort { $0.weekStart < $1.weekStart }
        return summaries
    }

    private var recentWorkoutWeeks: [WorkoutWeekSummary] {
        let all = workoutWeekSummaries
        if all.count <= 8 {
            return all
        } else {
            return Array(all.suffix(8))
        }
    }

    private var recentCardioWeeks: [CardioWeekSummary] {
        let all = cardioWeekSummaries
        if all.count <= 8 {
            return all
        } else {
            return Array(all.suffix(8))
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if store.sessions.isEmpty && cardio.entries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            headerStats

                            if !recentWorkoutWeeks.isEmpty {
                                strengthSessionsChart
                                strengthVolumeChart
                            }

                            if !recentCardioWeeks.isEmpty {
                                cardioDistanceChart
                                cardioMinutesChart
                            }

                            if recentWorkoutWeeks.isEmpty && recentCardioWeeks.isEmpty {
                                Text("Not enough data yet to show trends.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Trends")
        }
    }

    // MARK: - Header

    private var headerStats: some View {
        let totalStrengthSessions = store.sessions.count
        let totalStrengthVolume = workoutWeekSummaries.reduce(0) { $0 + $1.totalVolume }
        let totalStrengthSets = workoutWeekSummaries.reduce(0) { $0 + $1.totalSets }

        let totalCardioSessions = cardio.entries.count
        let totalCardioMinutes = cardioWeekSummaries.reduce(0) { $0 + $1.totalMinutes }
        let totalCardioDistance = cardioWeekSummaries.reduce(0) { $0 + $1.totalDistanceKm }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.title3.bold())

            HStack(spacing: 16) {
                statBox(title: "Strength sessions", value: "\(totalStrengthSessions)")
                statBox(title: "Strength volume", value: totalStrengthVolume > 0 ? "\(Int(totalStrengthVolume)) kg" : "-")
            }

            HStack(spacing: 16) {
                statBox(title: "Cardio sessions", value: "\(totalCardioSessions)")
                statBox(
                    title: "Cardio dist.",
                    value: totalCardioDistance > 0 ? String(format: "%.1f km", totalCardioDistance) : "-"
                )
                statBox(title: "Cardio time", value: totalCardioMinutes > 0 ? "\(totalCardioMinutes) min" : "-")
            }
        }
    }

    // MARK: - Strength charts

    private var strengthSessionsChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Strength: Sessions per week")
                .font(.headline)

            Chart(recentWorkoutWeeks) { week in
                BarMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Sessions", week.sessionCount)
                )
            }
            .frame(height: 180)

            if let last = recentWorkoutWeeks.last {
                Text("Last week: \(last.sessionCount) session\(last.sessionCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var strengthVolumeChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Strength: Volume per week")
                .font(.headline)

            Chart(recentWorkoutWeeks) { week in
                BarMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Volume (kg)", week.totalVolume)
                )
            }
            .frame(height: 180)

            if let last = recentWorkoutWeeks.last {
                Text("Last week: \(Int(last.totalVolume)) kg total volume")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Cardio charts

    private var cardioDistanceChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cardio: Distance per week")
                .font(.headline)

            Chart(recentCardioWeeks) { week in
                LineMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Distance (km)", week.totalDistanceKm)
                )
                PointMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Distance (km)", week.totalDistanceKm)
                )
            }
            .frame(height: 180)

            if let last = recentCardioWeeks.last {
                Text(String(format: "Last week: %.1f km", last.totalDistanceKm))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var cardioMinutesChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cardio: Minutes per week")
                .font(.headline)

            Chart(recentCardioWeeks) { week in
                BarMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Minutes", week.totalMinutes)
                )
            }
            .frame(height: 180)

            if let last = recentCardioWeeks.last {
                Text("Last week: \(last.totalMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No training data yet")
                .font(.headline)

            Text("Once you start logging workouts and cardio, you'll see your weekly trends here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
