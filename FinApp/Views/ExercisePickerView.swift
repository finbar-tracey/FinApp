//
//  ExercisePickerView.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//

import SwiftUI

struct ExercisePickerView: View {
    @EnvironmentObject var library: ExerciseLibraryStore

    let onSelect: (ExerciseTemplate) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(library.templates) { template in
                    Button {
                        onSelect(template)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.body)
                                Text(template.category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let reps = template.defaultReps {
                                Text("\(reps)x")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let weight = template.defaultWeight {
                                Text("\(weight, specifier: "%.1f") kg")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
