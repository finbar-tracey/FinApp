//
//  HealthView.swift
//  FinApp
//
//  Created by Finbar Tracey on 11/11/2025.
//
import SwiftUI

struct HealthView: View {
    @EnvironmentObject var health: HealthStore
    @AppStorage("useImperial") private var useImperial = false

    @State private var showingAdd = false
    @State private var editing: HealthEntry? = nil

    var body: some View {
        NavigationStack {
            List {
                if health.entries.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No Health Entries")
                                .font(.headline)
                            Text("Tap + to log weight, sleep, heart rate, water, or BP.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                } else {
                    Section {
                        ForEach(health.entries) { e in
                            entryRow(e)
                                .contentShape(Rectangle())
                                .onTapGesture { editing = e }
                                .swipeActions {
                                    Button("Edit") { editing = e }.tint(.blue)
                                    Button(role: .destructive) {
                                        if let i = health.entries.firstIndex(of: e) {
                                            health.delete(at: IndexSet(integer: i))
                                        }
                                    } label: { Text("Delete") }
                                }
                        }
                        .onDelete(perform: health.delete)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Health")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) { AddHealthEntryView().environmentObject(health) }
            .sheet(item: $editing) { e in
                AddHealthEntryView(existing: e).environmentObject(health)
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func entryRow(_ e: HealthEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(e.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.headline)
                Spacer()
                if let w = e.weightKg {
                    Text(displayWeight(w))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 12) {
                if let bf = e.bodyFatPercent { Label("\(Int(round(bf)))%", systemImage: "percent") }
                if let r = e.restingHeartRate { Label("\(r) bpm", systemImage: "heart.fill") }
                if let s = e.sleepHours { Label("\(String(format: "%.1f", s)) h", systemImage: "bed.double") }
                if let w = e.waterLitres { Label("\(String(format: "%.1f", w)) L", systemImage: "drop.fill") }
                if let s = e.systolicBP, let d = e.diastolicBP { Label("\(s)/\(d)", systemImage: "waveform.path.ecg") }
                if let s = e.steps { Label("\(s) steps", systemImage: "figure.walk") }

            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }

    private func displayWeight(_ kg: Double) -> String {
        if useImperial {
            let lbs = kg * 2.2046226218
            return "\(Int(round(lbs))) lb"
        }
        return "\(String(format: "%.1f", kg)) kg"
    }
}
