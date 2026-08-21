//
//  WaveformView.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import SwiftUI

struct WaveformView: View {
    let isPlaying: Bool
    var color: Color = .white

    var body: some View {
        if isPlaying {
            WaveformBars(color: color)
                .transition(.opacity)
        } else {
            HStack(spacing: 1.5) {
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(color.opacity(0.4))
                        .frame(width: 2, height: 2)
                }
            }
            .transition(.opacity)
        }
    }
}

/// All five bars are driven by one 20 fps timeline — a single view invalidation
/// per tick instead of five continuous display-rate animations, which keeps the
/// always-visible closed-notch waveform cheap on CPU.
private struct WaveformBars: View {
    let color: Color

    // Per-bar variation so the bars stay out of phase and read as organic.
    private static let speeds: [Double] = [2.6, 3.6, 2.3, 3.1, 2.4]
    private static let phases: [Double] = [0.0, 1.7, 0.9, 2.6, 1.3]
    private static let peaks: [CGFloat] = [1.0, 0.72, 0.9, 0.6, 0.82]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 1.4) {
                ForEach(0..<5, id: \.self) { index in
                    let wave = abs(sin(t * Self.speeds[index] + Self.phases[index]))
                    let scale = 0.3 + (Self.peaks[index] - 0.3) * CGFloat(wave)
                    RoundedRectangle(cornerRadius: 1.2)  // bar
                        .fill(color.opacity(0.9))
                        .frame(width: 2.4)
                        .scaleEffect(y: scale, anchor: .center)
                }
            }
        }
    }
}
