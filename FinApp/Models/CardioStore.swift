//
//  CardioStore.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//

import Foundation
import Combine

final class CardioStore: ObservableObject {
    @Published private(set) var entries: [CardioEntry] = []

    private let storageKey = "cardioEntries"
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()

        // Auto-save on changes
        $entries
            .dropFirst()
            .sink { [weak self] _ in
                self?.save()
            }
            .store(in: &cancellables)
    }

    // MARK: - CRUD

    func add(_ entry: CardioEntry) {
        entries.append(entry)
        sort()
    }

    func update(_ entry: CardioEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
        sort()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            entries.remove(at: index)
        }
    }

    func delete(_ entry: CardioEntry) {
        if let index = entries.firstIndex(of: entry) {
            entries.remove(at: index)
        }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            entries = []
            return
        }

        do {
            let decoded = try JSONDecoder().decode([CardioEntry].self, from: data)
            entries = decoded
            sort()
        } catch {
            print("Failed to decode CardioEntry: \(error)")
            entries = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode CardioEntry: \(error)")
        }
    }

    private func sort() {
        entries.sort { $0.date > $1.date } // newest first
    }
}
