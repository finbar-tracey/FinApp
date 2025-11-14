//
//  WorkoutSessionRow.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//
import SwiftUI

struct WorkoutSessionRow: View {
    let session: WorkoutSession

    private var totalExercises: Int {
        session.exercises.count
    }

    private var totalSets: Int {
        session.exercises
            .map { $0.sets.count }
            .reduce(0, +)
    }

    private var volumeKg: Int {
        let total = session.exercises
            .flatMap { $0.sets }
            .compactMap { set -> Double? in
                guard let w = set.weight else { return nil }
                return w * Double(set.reps)
            }
            .reduce(0, +)

        return Int(total)
    }

    private var mainCategory: String {
        // Naive “dominant category” based on first exercise
        session.exercises.first?.category ?? "Workout"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: title + date
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(mainCategory)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(session.date, format: .dateTime.day().month().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(session.date, format: .dateTime.hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Middle row: stats
            HStack(spacing: 16) {
                Label("\(totalExercises)", systemImage: "dumbbell")
                Label("\(totalSets)", systemImage: "number")

                if let d = session.durationMinutes {
                    Label("\(d) min", systemImage: "clock")
                }

                if volumeKg > 0 {
                    Label("\(volumeKg) kg", systemImage: "scalemass")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Notes indicator
            if let notes = session.notes, !notes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                    Text(notes)
                        .lineLimit(1)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
        .contentShape(Rectangle())
    }
}
