import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "list.bullet") }

            GoalsView()
                .tabItem { Label("Goals", systemImage: "target") }

            TimerView()
                .tabItem { Label("Timer", systemImage: "timer") }
        }
    }
}
