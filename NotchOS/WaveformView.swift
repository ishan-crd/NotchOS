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

    @State private var scale: CGFloat = 0.3

    private var duration: Double {
        [0.38, 0.28, 0.44, 0.32, 0.41][index % 5]
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color.opacity(0.9))
            .frame(width: 2.5)
            .scaleEffect(y: scale, anchor: .center)
            .onAppear { animate() }
    }

    private func animate() {
        let target = CGFloat.random(in: 0.3...1.0)
        let dur = duration * Double.random(in: 0.8...1.2)
        withAnimation(.easeInOut(duration: dur)) {
            scale = target
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + dur) {
            animate()
        }
    }
}
