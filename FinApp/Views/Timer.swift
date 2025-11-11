import SwiftUI
import UIKit

struct TimerView: View {
    @State private var isRunning = false
    @State private var seconds: Int = 60
    @State private var remaining: Int = 60
    @State private var timer: Timer?

    // 3-2-1 animation
    @State private var pulse = false

    // User preference for sounds
    @AppStorage("enableBeeps") private var enableBeeps = true

    var body: some View {
        VStack(spacing: 24) {
            Text("Rest Timer")
                .font(.title2).bold()

            ZStack {
                // Main time readout
                Text(timeString(from: remaining))
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                // Big 3-2-1 overlay
                if (1...3).contains(remaining) && isRunning {
                    Text("\(remaining)")
                        .font(.system(size: 120, weight: .black, design: .rounded))
                        .opacity(0.9)
                        .scaleEffect(pulse ? 1.15 : 0.8)
                        .opacity(pulse ? 1.0 : 0.2)
                        .animation(.easeInOut(duration: 0.25), value: pulse)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .frame(height: 130)

            VStack(spacing: 12) {
                Stepper("Duration (sec): \(seconds)", value: $seconds, in: 10...600, step: 5)
                    .onChange(of: seconds) { _, newValue in
                        if !isRunning { remaining = newValue }
                    }

                // Beeps toggle
                Toggle("Countdown beeps (3-2-1 & finish)", isOn: $enableBeeps)
            }
            .padding(.horizontal)

            HStack(spacing: 16) {
                Button(isRunning ? "Pause" : "Start") {
                    lightTap()
                    isRunning ? pause() : start()
                }
                .buttonStyle(.borderedProminent)

                Button("Reset") {
                    lightTap()
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

    // MARK: - Controls

    private func start() {
        if remaining == 0 { remaining = seconds }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if remaining > 0 {
                remaining -= 1

                // Light haptic + pulse animation + beep for last 3 seconds
                if remaining <= 3 && remaining > 0 {
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                    if enableBeeps { Sound.beep(.tick) }
                    withAnimation { pulse.toggle() }
                }
            } else {
                t.invalidate()
                isRunning = false

                // Success haptic + finish beep
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                if enableBeeps { Sound.beep(.done) }
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
        pulse = false
    }

    // MARK: - Helpers

    private func lightTap() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
    }

    private func timeString(from total: Int) -> String {
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
