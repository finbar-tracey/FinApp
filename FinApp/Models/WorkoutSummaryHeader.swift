//
//  WorkoutSummaryHeader.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//
import SwiftUI

struct WorkoutSummaryHeader: View {
    let sessions: [WorkoutSession]

    private var thisWeekSessions: [WorkoutSession] {
        let cal = Calendar.current
        return sessions.filter { cal.isDate($0.date, equalTo: .now, toGranularity: .weekOfYear) }
    }

    private var totalSessionsThisWeek: Int {
        thisWeekSessions.count
    }

    private var totalSetsThisWeek: Int {
        thisWeekSessions
            .flatMap { $0.exercises }
            .map { $0.sets.count }
            .reduce(0, +)
    }

    private var totalVolumeThisWeek: Int {
        let total = thisWeekSessions
            .flatMap { $0.exercises }
            .flatMap { $0.sets }
            .compactMap { set -> Double? in
                guard let w = set.weight else { return nil }
                return w * Double(set.reps)
            }
            .reduce(0, +)

        return Int(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This Week")
                    .font(.headline)
                Spacer()
                Text("\(totalSessionsThisWeek) workouts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                statBox(title: "Workouts", value: "\(totalSessionsThisWeek)")
                statBox(title: "Sets", value: "\(totalSetsThisWeek)")
                statBox(title: "Volume", value: totalVolumeThisWeek > 0 ? "\(totalVolumeThisWeek) kg" : "-")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
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
}
