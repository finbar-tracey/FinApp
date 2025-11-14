//
//  ExerciseTemplateForm.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//

import SwiftUI

struct ExerciseTemplateForm: View {
    enum Mode {
        case create
        case edit
    }

    let mode: Mode
    @State private var draft: ExerciseTemplate
    let onSave: (ExerciseTemplate) -> Void

    @Environment(\.dismiss) private var dismiss

    init(mode: Mode, initial: ExerciseTemplate, onSave: @escaping (ExerciseTemplate) -> Void) {
        self.mode = mode
        self._draft = State(initialValue: initial)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $draft.name)
                    TextField("Category", text: $draft.category)
                }

                Section("Defaults (optional)") {
                    Stepper(value: bindingForInt($draft.defaultReps, defaultValue: 8), in: 1...50) {
                        Text("Default reps: \(draft.defaultReps ?? 0)")
                    }

                    HStack {
                        Text("Default weight (kg)")
                        Spacer()
                        TextField("0", value: $draft.defaultWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }
            .navigationTitle(mode == .create ? "New Exercise" : "Edit Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // Helper to allow Stepper to bind to optional Int
    private func bindingForInt(_ binding: Binding<Int?>, defaultValue: Int) -> Binding<Int> {
        Binding<Int>(
            get: { binding.wrappedValue ?? defaultValue },
            set: { binding.wrappedValue = $0 }
        )
    }
}
