//
//  ProfileSummaryView.swift
//  FinApp
//
//  Created by Finbar Tracey on 12/11/2025.
//

import SwiftUI

struct ProfileSummaryView: View {
    let name: String
    let useImperial: Bool

    let workoutsThisWeek: Int
    let stepsThisWeek: Int
    let latestWeightText: String
    let latestRHRText: String
    let lastSyncText: String

    let syncing: Bool
    let onSync: () -> Void

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts.first!.first.map(String.init) ?? "")\(parts.last!.first.map(String.init) ?? "")".uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(.secondary.opacity(0.15))
                    Text(initials)
                        .font(.title2).bold()
                        .foregroundStyle(.primary)
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.headline)
                    Text("Last sync: \(lastSyncText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onSync()
                } label: {
                    if syncing {
                        ProgressView()
                    } else {
                        Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 16) {
                StatPill(systemImage: "figure.strengthtraining.traditional",
                         title: "Workouts",
                         value: "\(workoutsThisWeek)",
                         subtitle: "this week")

                StatPill(systemImage: "figure.walk",
                         title: "Steps",
                         value: numberString(stepsThisWeek),
                         subtitle: "this week")
            }

            HStack(spacing: 16) {
                StatPill(systemImage: "scalemass",
                         title: "Weight",
                         value: latestWeightText,
                         subtitle: useImperial ? "imperial" : "metric")

                StatPill(systemImage: "heart.fill",
                         title: "RHR",
                         value: latestRHRText,
                         subtitle: "resting")
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func numberString(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

private struct StatPill: View {
    let systemImage: String
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.headline)
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(.secondary.opacity(0.08)))
    }
}
