//
//  FinAppApp.swift
//  FinApp
//
//  Created by Finbar Tracey on 10/11/2025.
//

import SwiftUI

@main
struct FinAppApp: App {
    @StateObject private var store = WorkoutStore()

        var body: some Scene {
            WindowGroup {
                ContentView()
                    .environmentObject(store)
            }
        }
}
