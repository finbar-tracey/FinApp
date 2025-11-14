//
//  CardioView.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//
import SwiftUI

struct CardioView: View {
    @EnvironmentObject var cardio: CardioStore
    @EnvironmentObject var hk: HealthKitManager

    @State private var showingAdd = false
    @State private var editingEntry: CardioEntry?

    // Unified alert for PR + import messages
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showingAlert: Bool = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Cardio")
                .toolbar {
                    // PRs button (medal icon)
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            RunPRsView()
                        } label: {
                            Image(systemName: "medal")
                        }
                        .accessibilityLabel("Running PRs")
                    }

                    // Import from Health button
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            hk.importRecentCardioWorkouts(into: cardio, daysBack: 30) { newCount in
                                alertTitle = "Imported from Health"
                                if newCount == 0 {
                                    alertMessage = "No new workouts found in the last 30 days."
                                } else {
                                    alertMessage = "Imported \(newCount) new workout\(newCount == 1 ? "" : "s")."
                                }
                                showingAlert = true
                            }
                        } label: {
                            Image(systemName: "arrow.down.circle")
                        }
                        .accessibilityLabel("Import from Health")
                    }

                    // Add manual entry button
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAdd = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add cardio")
                    }
                }
                .sheet(isPresented: $showingAdd) {
                    CardioFormView(
                        mode: .create,
                        initial: CardioEntry(type: .run, date: Date(), distanceKm: nil, durationMinutes: 30)
                    ) { newEntry in
                        // Check PRs before adding
                        let labels = prLabelsForNewEntry(newEntry, isEdit: false)
                        cardio.add(newEntry)
                        showPRAlertIfNeeded(labels: labels)
                    }
                }
                .sheet(item: $editingEntry) { entry in
                    CardioFormView(
                        mode: .edit,
                        initial: entry
                    ) { updated in
                        // Check PRs for updated entry
                        let labels = prLabelsForNewEntry(updated, isEdit: true)
                        cardio.update(updated)
                        showPRAlertIfNeeded(labels: labels)
                    }
                }
                .alert(alertTitle, isPresented: $showingAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(alertMessage)
                }
        }
    }

    // MARK: - Main content

    @ViewBuilder
    private var content: some View {
        if cardio.entries.isEmpty {
            emptyState
        } else {
            List {
                ForEach(cardio.entries) { entry in
                    NavigationLink {
                        CardioDetailView(entry: entry)
                    } label: {
                        row(for: entry)
                    }
                    .swipeActions {
                        Button("Edit") {
                            editingEntry = entry
                        }
                        .tint(.blue)

                        Button(role: .destructive) {
                            cardio.delete(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: cardio.delete)
            }
        }
    }

    // MARK: - Runs + PR IDs (for list medals)

    /// All valid run entries (used for PR logic).
    private var runs: [CardioEntry] {
        cardio.entries.filter {
            $0.type == .run &&
            ($0.distanceKm ?? 0) > 0 &&
            $0.durationMinutes > 0
        }
    }

    /// Set of entry IDs that hold *any* PR (1K / 5K / 10K / Half / longest / fastest pace).
    private var prEntryIDs: Set<UUID> {
        var ids = Set<UUID>()

        // Distance PRs
        if let e1 = bestEntry(for: 1.0)      { ids.insert(e1.id) }
        if let e5 = bestEntry(for: 5.0)      { ids.insert(e5.id) }
        if let e10 = bestEntry(for: 10.0)    { ids.insert(e10.id) }
        if let eHalf = bestEntry(for: 21.1)  { ids.insert(eHalf.id) }

        // Longest run
        if let longest = runs.max(by: { ($0.distanceKm ?? 0) < ($1.distanceKm ?? 0) }) {
            ids.insert(longest.id)
        }

        // Fastest avg pace
        if let fastest = runs.min(by: { ($0.paceMinutesPerKm ?? .infinity) < ($1.paceMinutesPerKm ?? .infinity) }) {
            ids.insert(fastest.id)
        }

        return ids
    }

    /// Best (fastest) entry for a target distance, based on avg pace and estimated time.
    private func bestEntry(for targetKm: Double) -> CardioEntry? {
        var best: (entry: CardioEntry, time: Double)?

        for run in runs {
            guard let time = estimatedTime(for: targetKm, entry: run) else { continue }
            if let current = best {
                if time < current.time {
                    best = (run, time)
                }
            } else {
                best = (run, time)
            }
        }

        return best?.entry
    }

    // MARK: - Row / empty state

    private func row(for entry: CardioEntry) -> some View {
        let date = entry.date.formatted(date: .abbreviated, time: .shortened)
        let isPR = prEntryIDs.contains(entry.id)

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.type.rawValue)
                        .font(.headline)

                    if isPR {
                        Image(systemName: "medal.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let distance = entry.distanceKm {
                    Text("\(distance, specifier: "%.2f") km")
                } else {
                    Text("\(entry.durationMinutes) min")
                }

                if let pace = entry.paceMinutesPerKm {
                    Text("\(paceString(from: pace)) /km")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let hr = entry.avgHeartRate {
                    Text("\(hr) bpm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No cardio logged yet")
                .font(.headline)

            Text("Add your runs, cycles, rows and walks here to track your endurance work.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Helpers (pace)

    private func paceString(from minutesPerKm: Double) -> String {
        if minutesPerKm.isNaN || minutesPerKm.isInfinite { return "-" }
        let minutes = Int(minutesPerKm)
        let seconds = Int((minutesPerKm - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - PR detection (for popup)

    /// Returns a list of PR labels (e.g. ["5K PR", "Longest run"]) that this entry achieves.
    private func prLabelsForNewEntry(_ entry: CardioEntry, isEdit: Bool) -> [String] {
        // Only care about valid runs
        guard entry.type == .run,
              let distance = entry.distanceKm,
              distance > 0,
              entry.durationMinutes > 0 else {
            return []
        }

        // Runs *before* this change
        var existingRuns = cardio.entries.filter {
            $0.type == .run &&
            ($0.distanceKm ?? 0) > 0 &&
            $0.durationMinutes > 0
        }

        // If editing, remove the old version of this entry from the baseline
        if isEdit {
            existingRuns.removeAll(where: { $0.id == entry.id })
        }

        var labels: [String] = []

        // Distance-based PRs (estimated from average pace)
        if isNewDistancePR(targetKm: 1.0, entry: entry, existingRuns: existingRuns) {
            labels.append("1K PR")
        }
        if isNewDistancePR(targetKm: 5.0, entry: entry, existingRuns: existingRuns) {
            labels.append("5K PR")
        }
        if isNewDistancePR(targetKm: 10.0, entry: entry, existingRuns: existingRuns) {
            labels.append("10K PR")
        }
        if isNewDistancePR(targetKm: 21.1, entry: entry, existingRuns: existingRuns) {
            labels.append("Half PR")
        }

        // Longest run
        if isNewLongestRun(entry: entry, existingRuns: existingRuns) {
            labels.append("Longest run")
        }

        // Fastest pace (lowest min/km)
        if isNewFastestPace(entry: entry, existingRuns: existingRuns) {
            labels.append("Fastest pace")
        }

        return labels
    }

    private func isNewDistancePR(targetKm: Double, entry: CardioEntry, existingRuns: [CardioEntry]) -> Bool {
        guard let newTime = estimatedTime(for: targetKm, entry: entry) else {
            return false
        }

        // Old best
        let oldBestTime = bestEstimatedTime(for: targetKm, in: existingRuns)

        // If there was no previous run far enough -> first PR
        guard let old = oldBestTime else {
            return true
        }

        // Strictly faster than old
        return newTime < old
    }

    private func bestEstimatedTime(for targetKm: Double, in runs: [CardioEntry]) -> Double? {
        var best: Double?

        for run in runs {
            guard let time = estimatedTime(for: targetKm, entry: run) else { continue }
            if let current = best {
                if time < current {
                    best = time
                }
            } else {
                best = time
            }
        }

        return best
    }

    private func estimatedTime(for targetKm: Double, entry: CardioEntry) -> Double? {
        guard let dist = entry.distanceKm,
              dist >= targetKm,
              dist > 0 else {
            return nil
        }

        let pace = Double(entry.durationMinutes) / dist
        return pace * targetKm // minutes
    }

    private func isNewLongestRun(entry: CardioEntry, existingRuns: [CardioEntry]) -> Bool {
        guard let newDist = entry.distanceKm, newDist > 0 else {
            return false
        }

        let oldMax = existingRuns.compactMap { $0.distanceKm }.max()

        // No previous distance -> PR
        guard let old = oldMax else {
            return true
        }

        // Strictly longer than old
        return newDist > old
    }

    private func isNewFastestPace(entry: CardioEntry, existingRuns: [CardioEntry]) -> Bool {
        guard let newPace = entry.paceMinutesPerKm else {
            return false
        }

        let oldBestPace = existingRuns
            .compactMap { $0.paceMinutesPerKm }
            .min()

        // No previous pace -> PR
        guard let old = oldBestPace else {
            return true
        }

        // Lower minutes per km = faster pace
        return newPace < old
    }

    private func showPRAlertIfNeeded(labels: [String]) {
        guard !labels.isEmpty else { return }
        alertTitle = "New PR!"
        alertMessage = labels.joined(separator: ", ")
        showingAlert = true
    }
}
