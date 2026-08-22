//
//  MarqueeText.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import SwiftUI

/// Scrolls its text horizontally when it doesn't fit; renders as a plain
/// truncated-free Text when it does. Driven by a low-rate TimelineView so it
/// stays cheap while visible.
struct MarqueeText: View {
    let text: String
    let font: Font
    var color: Color = .white
    /// When false the text renders statically - pass the panel's visibility so
    /// hidden-but-mounted players don't keep a timeline running.
    var active: Bool = true

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    private let gap: CGFloat = 32
    private let speed: CGFloat = 24 // points per second

    private var needsScroll: Bool { active && textWidth > containerWidth + 1 }

    var body: some View {
        GeometryReader { geo in
            Group {
                if needsScroll {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                        let cycle = (textWidth + gap) / speed
                        let phase = context.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: Double(cycle))
                        let offset = -CGFloat(phase) * speed
                        HStack(spacing: gap) {
                            measuredText
                            measuredText
                        }
                        .offset(x: offset)
                    }
                } else {
                    measuredText
                }
            }
            .frame(width: geo.size.width, alignment: .leading)
            .clipped()
            .onAppear { containerWidth = geo.size.width }
            .onChange(of: geo.size.width) { containerWidth = $0 }
        }
    }

    private var measuredText: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize()
            .background(GeometryReader { proxy in
                Color.clear
                    .onAppear { textWidth = proxy.size.width }
                    .onChange(of: text) { _ in textWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { textWidth = $0 }
            })
    }
}
