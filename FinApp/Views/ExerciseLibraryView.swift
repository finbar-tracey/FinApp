//
//  ExerciseLibraryView.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//

import SwiftUI

struct ExerciseLibraryView: View {
    @EnvironmentObject var library: ExerciseLibraryStore

    @State private var showingAdd = false
    @State private var editingTemplate: ExerciseTemplate?

    var body: some View {
        NavigationStack {
            Group {
                if library.templates.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(library.templates) { template in
                            NavigationLink {
                                ExerciseDetailView(template: template)
                            } label: {
                                row(for: template)
                            }
                            .swipeActions {
                                Button("Edit") {
                                    editingTemplate = template
                                }
                                .tint(.blue)

                                Button(role: .destructive) {
                                    library.delete(template)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add exercise")
                }
            }
            .sheet(isPresented: $showingAdd) {
                ExerciseTemplateForm(
                    mode: .create,
                    initial: ExerciseTemplate(name: "", category: "Strength")
                ) { newTemplate in
                    library.add(newTemplate)
                }
            }
            .sheet(item: $editingTemplate) { template in
                ExerciseTemplateForm(
                    mode: .edit,
                    initial: template
                ) { updated in
                    library.update(updated)
                }
            }
        }
    }

    // MARK: - Row + empty state

    private func row(for template: ExerciseTemplate) -> some View {
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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No exercises yet")
                .font(.headline)

            Text("Add your favourite exercises here so you can quickly reuse them when logging workouts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
