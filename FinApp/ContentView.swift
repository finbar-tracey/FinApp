import SwiftUI

struct ContentView: View {
    // Inherit the shared objects injected by FinAppApp
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var health: HealthStore
    @EnvironmentObject var hk: HealthKitManager

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house") }

            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "dumbbell") }

            HealthView()
                .tabItem { Label("Health", systemImage: "heart.text.square") }
            
            CardioView()
                .tabItem { Label("Cardio", systemImage: "figure.run") }

            GoalsView()
                .tabItem { Label("Goals", systemImage: "target") }

            TimerView()
                .tabItem { Label("Timer", systemImage: "timer") }
            
            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.bar.xaxis") }
            
            ExerciseLibraryView()
                .tabItem { Label("Exercises", systemImage: "list.bullet.rectangle") }
        }
    }
}
