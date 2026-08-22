//
//  NotchView.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import SwiftUI

struct NotchView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject private var nowPlaying = NowPlayingManager.shared

    @State var dropTargeting: Bool = false

    private var musicExpand: CGFloat {
        nowPlaying.hasNowPlaying && vm.status == .closed ? 72 : 0
    }

    var notchSize: CGSize {
        switch vm.status {
        case .closed:
            var ans = CGSize(
                width: vm.deviceNotchRect.width - 4 + musicExpand,
                height: vm.deviceNotchRect.height
            )
            if ans.width < 0 { ans.width = 0 }
            if ans.height < 0 { ans.height = 0 }
            return ans
        case .opened:
            return vm.notchOpenedSize
        case .popping:
            return .init(
                width: vm.deviceNotchRect.width + musicExpand,
                height: vm.deviceNotchRect.height + 4
            )
        }
    }

    var notchCornerRadius: CGFloat {
        switch vm.status {
        case .closed: 8
        case .opened: 32
        case .popping: 10
        }
    }

    var body: some View {
        notch
            .opacity(vm.notchVisible || nowPlaying.hasNowPlaying ? 1 : 0.3)
            .background(dragDetector)
            .animation(vm.status == .opened ? vm.openAnimation : vm.closeAnimation, value: vm.status)
            .preferredColorScheme(.dark)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// The opened panel content. Lives INSIDE the masked notch surface, so the
    /// springing shape clips and reveals it - the boring.notch mechanic that
    /// makes open/close read as one surface growing and shrinking.
    var openContent: some View {
        VStack(spacing: vm.spacing) {
            NotchHeaderView(vm: vm)
            NotchContentView(vm: vm)
                .frame(maxHeight: .infinity)
        }
        .padding(vm.spacing)
        .frame(width: vm.notchOpenedSize.width, height: vm.notchOpenedSize.height)
        // Keyed to status rather than part of the transition, so the blur rides
        // the same spring as the shrinking shape and the content dissolves into
        // the notch.
        .blur(radius: vm.status == .opened ? 0 : 20)
        .transition(
            .scale(scale: 0.8, anchor: .top)
                .combined(with: .move(edge: .top))
                .combined(with: .opacity)
                .animation(.smooth(duration: 0.35))
        )
    }

    @ViewBuilder
    var notchFill: some View {
        if vm.status != .opened {
            Color.black
        } else {
            switch vm.glassStyle {
            case .flat:
                Color(red: 0.027, green: 0.027, blue: 0.031)
            case .matte:
                LinearGradient(
                    colors: [Color(red: 0.075, green: 0.075, blue: 0.086), Color(red: 0.031, green: 0.031, blue: 0.039)],
                    startPoint: .top, endPoint: .bottom
                )
            case .heavy:
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    LinearGradient(
                        colors: [Color(red: 0.086, green: 0.086, blue: 0.102).opacity(0.86), Color(red: 0.031, green: 0.031, blue: 0.039).opacity(0.92)],
                        startPoint: .top, endPoint: .bottom
                    )
                }
            }
        }
    }

    var notch: some View {
        ZStack(alignment: .top) {
            notchFill
            if nowPlaying.hasNowPlaying && vm.status != .opened {
                notchMusicOverlay
            }
            if vm.status == .opened {
                openContent
            }
        }
        .frame(
            width: notchSize.width + notchCornerRadius * 2,
            height: notchSize.height
        )
        .mask(notchBackgroundMaskGroup)
        .shadow(
            color: .black.opacity(([.opened, .popping].contains(vm.status)) ? 1 : 0),
            radius: 16
        )
        .animation(vm.animation, value: nowPlaying.hasNowPlaying)
        .animation(vm.animation, value: vm.glassStyle)
    }

    var notchMusicOverlay: some View {
        HStack {
            // Album art on the left
            Group {
                if let artwork = nowPlaying.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.white.opacity(0.15)
                        .overlay {
                            Image(systemName: "music.note")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                }
            }
            .frame(width: 20, height: 20)
            .clipShape(RoundedRectangle(cornerRadius: 4.5))
            .padding(.leading, 8)

            Spacer()

            // Waveform bars on the right
            WaveformView(isPlaying: nowPlaying.isPlaying, color: Color(nsColor: nowPlaying.dominantColor))
                .frame(width: 20, height: 10)
                .padding(.trailing, 8)
        }
        .frame(width: notchSize.width, height: notchSize.height)
        .allowsHitTesting(false)
    }

    var notchBackgroundMaskGroup: some View {
        Rectangle()
            .foregroundStyle(.black)
            .frame(
                width: notchSize.width,
                height: notchSize.height
            )
            .clipShape(.rect(
                bottomLeadingRadius: notchCornerRadius,
                bottomTrailingRadius: notchCornerRadius
            ))
            .overlay(alignment: .topLeading) {
                NotchFillet()
                    .fill(.black)
                    .frame(width: notchCornerRadius, height: notchCornerRadius)
                    .offset(x: -notchCornerRadius + 0.5, y: -0.5)
            }
            .overlay(alignment: .topTrailing) {
                NotchFillet()
                    .fill(.black)
                    .scaleEffect(x: -1)
                    .frame(width: notchCornerRadius, height: notchCornerRadius)
                    .offset(x: notchCornerRadius - 0.5, y: -0.5)
            }
    }

    /// The concave "flare" that joins the notch's vertical edge to the menu bar.
    /// Drawn as a plain filled path — no blend modes, which composite unreliably
    /// inside masks on some macOS versions.
    private struct NotchFillet: Shape {
        func path(in rect: CGRect) -> Path {
            let r = min(rect.width, rect.height)
            var p = Path()
            p.move(to: .zero)
            p.addArc(
                center: CGPoint(x: 0, y: r), radius: r,
                startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false
            )
            p.addLine(to: CGPoint(x: r, y: 0))
            p.closeSubpath()
            return p
        }
    }

    @ViewBuilder
    var dragDetector: some View {
        RoundedRectangle(cornerRadius: notchCornerRadius)
            .foregroundStyle(Color.black.opacity(0.001)) // fuck you apple and 0.001 is the smallest we can have
            .contentShape(Rectangle())
            .frame(width: notchSize.width + vm.dropDetectorRange, height: notchSize.height + vm.dropDetectorRange)
            .onDrop(of: [.data], isTargeted: $dropTargeting) { _ in true }
            .onChange(of: dropTargeting) { isTargeted in
                if isTargeted, vm.status == .closed {
                    // Open the notch when a file is dragged over it
                    vm.notchOpen(.drag)
                    vm.hapticSender.send()
                } else if !isTargeted {
                    // Close the notch when the dragged item leaves the area
                    let mouseLocation: NSPoint = NSEvent.mouseLocation
                    if !vm.notchOpenedRect.insetBy(dx: vm.inset, dy: vm.inset).contains(mouseLocation) {
                        vm.notchClose()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
