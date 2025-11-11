//
//  AddHealthEntryView..swift
//  FinApp
//
//  Created by Finbar Tracey on 11/11/2025.
//
import SwiftUI

struct AddHealthEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var health: HealthStore
    @AppStorage("useImperial") private var useImperial = false

    // If set, we're editing
    var existing: HealthEntry?

    // Form state
    @State private var date = Date()
    @State private var weight = ""         // kg (store as kg)
    @State private var bodyFat = ""        // %
    @State private var rhr = ""            // bpm
    @State private var sleep = ""          // hours
    @State private var water = ""          // litres
    @State private var sys = ""            // systolic
    @State private var dia = ""            // diastolic

    init(existing: HealthEntry? = nil) {
        self.existing = existing
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                Section("Body") {
                    TextField("Weight (\(useImperial ? "lb" : "kg"))", text: $weight)
                        .keyboardType(.decimalPad)
                    TextField("Body Fat (%)", text: $bodyFat)
                        .keyboardType(.decimalPad)
                }
                Section("Vitals") {
                    TextField("Resting HR (bpm)", text: $rhr)
                        .keyboardType(.numberPad)
                    HStack {
                        TextField("Systolic", text: $sys)
                            .keyboardType(.numberPad)
                        Text("/")
                        TextField("Diastolic", text: $dia)
                            .keyboardType(.numberPad)
                    }
                }
                Section("Recovery") {
                    TextField("Sleep (hours)", text: $sleep)
                        .keyboardType(.decimalPad)
                    TextField("Water (L)", text: $water)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(existing == nil ? "Add Health" : "Edit Health")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existing == nil ? "Save" : "Update") { save() }
                }
            }
            .onAppear {
                guard let e = existing else { return }
                date = e.date
                if let w = e.weightKg {
                    weight = useImperial ? String(format: "%.1f", w * 2.2046226218) : String(w)
                }
                if let bf = e.bodyFatPercent { bodyFat = String(bf) }
                if let r = e.restingHeartRate { rhr = String(r) }
                if let sl = e.sleepHours { sleep = String(sl) }
                if let wa = e.waterLitres { water = String(wa) }
                if let s = e.systolicBP { sys = String(s) }
                if let d = e.diastolicBP { dia = String(d) }
            }
        }
    }

    private func save() {
        // Parse entries
        func dble(_ s: String) -> Double? { Double(s.replacingOccurrences(of: ",", with: ".")) }
        func intl(_ s: String) -> Int? { Int(s) }

        // Always store weight in kg
        let kg: Double? = {
            guard let raw = dble(weight) else { return nil }
            return useImperial ? (raw / 2.2046226218) : raw
        }()

        var entry = existing ?? HealthEntry()
        entry.date = date
        entry.weightKg = kg
        entry.bodyFatPercent = dble(bodyFat)
        entry.restingHeartRate = intl(rhr)
        entry.sleepHours = dble(sleep)
        entry.waterLitres = dble(water)
        entry.systolicBP = intl(sys)
        entry.diastolicBP = intl(dia)

        if existing == nil { health.add(entry) } else { health.update(entry) }
        dismiss()
    }
}
