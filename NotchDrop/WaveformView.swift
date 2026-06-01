import SwiftUI

struct WaveformView: View {
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<5, id: \.self) { index in
                WaveformBar(isPlaying: isPlaying, index: index)
            }
        }
    }
}

private struct WaveformBar: View {
    let isPlaying: Bool
    let index: Int

    @State private var animating = false

    private var delay: Double { Double(index) * 0.12 }

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(Color.white.opacity(0.9))
            .frame(width: 2.5)
            .scaleEffect(y: animating ? CGFloat.random(in: 0.5...1.0) : 0.3, anchor: .center)
            .onChange(of: isPlaying) { playing in
                if playing {
                    withAnimation(.easeInOut(duration: Double.random(in: 0.3...0.6)).repeatForever(autoreverses: true).delay(delay)) {
                        animating = true
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        animating = false
                    }
                }
            }
            .onAppear {
                guard isPlaying else { return }
                withAnimation(.easeInOut(duration: Double.random(in: 0.3...0.6)).repeatForever(autoreverses: true).delay(delay)) {
                    animating = true
                }
            }
    }
}
