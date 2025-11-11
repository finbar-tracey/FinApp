//
//  FinAppApp.swift
//  FinApp
//
//  Created by Finbar Tracey on 10/11/2025.
//
import SwiftUI

@main
struct FinAppApp: App {
    // Single shared instances for the whole app
    @StateObject private var store  = WorkoutStore()
    @StateObject private var health = HealthStore()
    @StateObject private var hk     = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(health)
                .environmentObject(hk)
        }
    }
}
