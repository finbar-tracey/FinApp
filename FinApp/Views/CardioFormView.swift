//
//  CardioFormView.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//

import SwiftUI

struct CardioFormView: View {
    enum Mode {
        case create
        case edit
    }

    let mode: Mode
    @State private var draft: CardioEntry
    let onSave: (CardioEntry) -> Void

    @Environment(\.dismiss) private var dismiss

    init(mode: Mode, initial: CardioEntry, onSave: @escaping (CardioEntry) -> Void) {
        self.mode = mode
        self._draft = State(initialValue: initial)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    Picker("Type", selection: $draft.type) {
                        ForEach(CardioType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    DatePicker(
                        "Date",
                        selection: $draft.date,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    HStack {
                        Text("Duration (min)")
                        Spacer()
                        TextField("30", value: $draft.durationMinutes, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Distance (km)")
                        Spacer()
                        TextField("5.0", value: Binding(
                            get: { draft.distanceKm ?? 0 },
                            set: { value in
                                draft.distanceKm = value == 0 ? nil : value
                            }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    }

                    HStack {
                        Text("Avg HR (bpm)")
                        Spacer()
                        TextField("140", value: Binding(
                            get: { draft.avgHeartRate ?? 0 },
                            set: { value in
                                draft.avgHeartRate = value == 0 ? nil : value
                            }
                        ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    }
                }

                Section("Notes") {
                    TextField("How did it feel?", text: Binding(
                        get: { draft.notes ?? "" },
                        set: { newValue in
                            draft.notes = newValue.isEmpty ? nil : newValue
                        }
                    ), axis: .vertical)
                    .lineLimit(2...5)
                }
            }
            .navigationTitle(mode == .create ? "New Cardio" : "Edit Cardio")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(draft.durationMinutes <= 0)
                }
            }
        }
    }
}
