import SwiftUI

struct TimerView: View {
    @State private var isRunning = false
    @State private var seconds: Int = 60     // default 60-second rest
    @State private var remaining: Int = 60
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 24) {
            Text("Rest Timer")
                .font(.title2).bold()

            Text(timeString(from: remaining))
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 16) {
                Stepper("Duration (sec): \(seconds)", value: $seconds, in: 10...600, step: 5)
                    .onChange(of: seconds) { _, newValue in
                        if !isRunning { remaining = newValue }
                    }
            }
            .padding(.horizontal)

            HStack(spacing: 16) {
                Button(isRunning ? "Pause" : "Start") {
                    isRunning ? pause() : start()
                }
                .buttonStyle(.borderedProminent)

                Button("Reset") {
                    reset()
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
        .onAppear { remaining = seconds }
        .onDisappear { timer?.invalidate() }
    }

    private func start() {
        if remaining == 0 { remaining = seconds }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if remaining > 0 {
                remaining -= 1
            } else {
                t.invalidate()
                isRunning = false
                // Optional: haptic or sound here later
            }
        }
    }

    private func pause() {
        isRunning = false
        timer?.invalidate()
    }

    private func reset() {
        isRunning = false
        timer?.invalidate()
        remaining = seconds
    }

    private func timeString(from total: Int) -> String {
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
