//
//  SleepBreakdownView.swift
//  FinApp
//
//  Created by ChatGPT on 12/11/2025.
//
import SwiftUI

struct SleepBreakdownView: View {
    let breakdown: SleepBreakdown

    // normalized widths
    private var remPct: CGFloat { CGFloat(breakdown.remPct) }
    private var deepPct: CGFloat { CGFloat(breakdown.deepPct) }
    private var corePct: CGFloat { CGFloat(breakdown.corePct) }
    private var unspecPct: CGFloat { CGFloat(breakdown.unspecifiedPct) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Total summary
            Text("Total \(formatHours(breakdown.totalHours))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Stacked horizontal bar
            GeometryReader { geo in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 6)
                        .frame(width: geo.size.width * remPct, height: 12)
                        .foregroundStyle(Color.red.opacity(0.8))
                        .accessibilityLabel("REM")
                        .accessibilityValue("\(Int(breakdown.remPct * 100)) percent")

                    RoundedRectangle(cornerRadius: 6)
                        .frame(width: geo.size.width * deepPct, height: 12)
                        .foregroundStyle(Color.blue.opacity(0.8))
                        .accessibilityLabel("Deep")
                        .accessibilityValue("\(Int(breakdown.deepPct * 100)) percent")

                    RoundedRectangle(cornerRadius: 6)
                        .frame(width: geo.size.width * corePct, height: 12)
                        .foregroundStyle(Color.green.opacity(0.8))
                        .accessibilityLabel("Core")
                        .accessibilityValue("\(Int(breakdown.corePct * 100)) percent")

                    // Only draw unspecified if non-trivial
                    if unspecPct > 0.01 {
                        RoundedRectangle(cornerRadius: 6)
                            .frame(width: geo.size.width * unspecPct, height: 12)
                            .foregroundStyle(Color.gray.opacity(0.6))
                            .accessibilityLabel("Unspecified")
                            .accessibilityValue("\(Int(breakdown.unspecifiedPct * 100)) percent")
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .frame(height: 14)

            // Legend
            VStack(alignment: .leading, spacing: 6) {
                LegendRow(swatch: .red.opacity(0.8),   label: "REM",        hours: breakdown.remHours,        pct: breakdown.remPct)
                LegendRow(swatch: .blue.opacity(0.8),  label: "Deep",       hours: breakdown.deepHours,       pct: breakdown.deepPct)
                LegendRow(swatch: .green.opacity(0.8), label: "Core",       hours: breakdown.coreHours,       pct: breakdown.corePct)
                if breakdown.unspecifiedSeconds > 0 {
                    LegendRow(swatch: .gray.opacity(0.6), label: "Unspecified", hours: breakdown.unspecifiedHours, pct: breakdown.unspecifiedPct)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatHours(_ h: Double) -> String {
        let mins = Int(round(h * 60))
        let hours = mins / 60
        let m = mins % 60
        return m == 0 ? "\(hours) h" : "\(hours) h \(m) min"
    }
}

private struct LegendRow: View {
    let swatch: Color
    let label: String
    let hours: Double
    let pct: Double

    var body: some View {
        HStack {
            Circle().fill(swatch).frame(width: 10, height: 10)
            Text(label)
            Spacer()
            Text("\(formatHours(hours)) • \(Int(round(pct * 100)))%")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }

    private func formatHours(_ h: Double) -> String {
        let mins = Int(round(h * 60))
        let hours = mins / 60
        let m = mins % 60
        return m == 0 ? "\(hours) h" : "\(hours) h \(m) min"
    }
}
