//
//  HealthStore.swift
//  FinApp
//
//  Created by Finbar Tracey on 11/11/2025.
//

import Foundation
import Combine

final class HealthStore: ObservableObject {
    @Published private(set) var entries: [HealthEntry] = []

    private let key = "health_entries"

    init() {
        load()
        sort()
    }

    // CRUD
    func add(_ entry: HealthEntry) {
        entries.insert(entry, at: 0)
        sort()
        save()
    }

    func update(_ entry: HealthEntry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[i] = entry
            sort()
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        for o in offsets.sorted(by: >) { entries.remove(at: o) }
        save()
    }

    // Helpers
    private func sort() {
        entries.sort { $0.date > $1.date }
    }

    // Persistence
    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to save health entries: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        do {
            entries = try JSONDecoder().decode([HealthEntry].self, from: data)
        } catch {
            print("Failed to load health entries: \(error)")
            entries = []
        }
    }
}
