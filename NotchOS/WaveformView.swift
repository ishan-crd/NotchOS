import SwiftUI

struct WaveformView: View {
    let isPlaying: Bool
    var color: Color = .white

    var body: some View {
        if isPlaying {
            HStack(spacing: 1.5) {
                ForEach(0..<5, id: \.self) { index in
                    WaveformBar(color: color, index: index)
                }
            }
            .transition(.opacity)
        } else {
            HStack(spacing: 2) {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(color.opacity(0.4))
                        .frame(width: 2, height: 2)
                }
            }
            .transition(.opacity)
        }
    }
}

private struct WaveformBar: View {
    let color: Color
    let index: Int

    @State private var animating = false

    private var delay: Double { Double(index) * 0.12 }
    private var targetScale: CGFloat {
        [0.65, 0.9, 0.75, 0.85, 0.7][index % 5]
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color.opacity(0.9))
            .frame(width: 2.5)
            .scaleEffect(y: animating ? targetScale : 0.3, anchor: .center)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(delay)) {
                    animating = true
                }
            }
    }
}
