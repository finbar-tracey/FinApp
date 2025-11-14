//
//  ExerciseLibraryStore.swift
//  FinApp
//
//  Created by Finbar Tracey on 15/11/2025.
//
import Foundation
import Combine

final class ExerciseLibraryStore: ObservableObject {
    @Published private(set) var templates: [ExerciseTemplate] = []

    private let storageKey = "exerciseLibraryTemplates"
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()

        // Auto-save whenever templates changes
        $templates
            .dropFirst()
            .sink { [weak self] _ in
                self?.save()
            }
            .store(in: &cancellables)
    }

    // MARK: - CRUD

    func add(_ template: ExerciseTemplate) {
        templates.append(template)
    }

    func update(_ template: ExerciseTemplate) {
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else { return }
        templates[index] = template
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            templates.remove(at: index)
        }
    }

    func delete(_ template: ExerciseTemplate) {
        if let index = templates.firstIndex(of: template) {
            templates.remove(at: index)
        }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            templates = defaultSeed()
            return
        }

        do {
            let decoded = try JSONDecoder().decode([ExerciseTemplate].self, from: data)
            templates = decoded
        } catch {
            print("Failed to decode exercise templates: \(error)")
            templates = defaultSeed()
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(templates)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode exercise templates: \(error)")
        }
    }

    private func defaultSeed() -> [ExerciseTemplate] {
        [
            ExerciseTemplate(name: "Barbell Bench Press", category: "Strength"),
            ExerciseTemplate(name: "Back Squat", category: "Strength"),
            ExerciseTemplate(name: "Deadlift", category: "Strength"),
            ExerciseTemplate(name: "Pull-up", category: "Strength"),
            ExerciseTemplate(name: "Running", category: "Cardio"),
            ExerciseTemplate(name: "Cycling", category: "Cardio")
        ]
    }
}
