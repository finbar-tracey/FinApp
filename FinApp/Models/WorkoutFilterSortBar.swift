//
//  WorkoutFilterSortBar.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//

import SwiftUI

struct WorkoutFilterSortBar: View {
    @Binding var selectedFilter: WorkoutFilter
    @Binding var sortNewestFirst: Bool
    let sessionCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("\(sessionCount) session\(sessionCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WorkoutFilter.allCases) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            Text(filter.label)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    selectedFilter == filter
                                        ? Color.accentColor.opacity(0.15)
                                        : Color(.secondarySystemBackground)
                                )
                                .foregroundStyle(
                                    selectedFilter == filter
                                        ? Color.accentColor
                                        : Color.primary
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Picker("Sort", selection: $sortNewestFirst) {
                Text("Recent").tag(true)
                Text("A–Z").tag(false)
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 4)
    }
}

