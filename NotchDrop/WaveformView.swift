import SwiftUI

struct WaveformView: View {
    let isPlaying: Bool

    private let barCount = 5
    private let barWidth: CGFloat = 2.5
    private let spacing: CGFloat = 1.5

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(isPlaying: isPlaying, index: index)
            }
        }
    }
}

private struct WaveformBar: View {
    let isPlaying: Bool
    let index: Int

    @State private var height: CGFloat = 0.3

    private var baseDelay: Double {
        Double(index) * 0.12
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(Color.white.opacity(0.9))
            .frame(width: 2.5)
            .scaleEffect(y: isPlaying ? height : 0.3, anchor: .center)
            .animation(
                isPlaying
                    ? .easeInOut(duration: Double.random(in: 0.3...0.6))
                        .repeatForever(autoreverses: true)
                        .delay(baseDelay)
                    : .easeOut(duration: 0.3),
                value: isPlaying
            )
            .onAppear {
                if isPlaying { animate() }
            }
            .onChange(of: isPlaying) { playing in
                if playing { animate() } else { height = 0.3 }
            }
    }

    private func animate() {
        withAnimation(
            .easeInOut(duration: Double.random(in: 0.3...0.6))
            .repeatForever(autoreverses: true)
            .delay(baseDelay)
        ) {
            height = CGFloat.random(in: 0.5...1.0)
        }
    }
}
