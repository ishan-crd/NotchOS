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
    @ObservedObject private var battery = BatteryMonitor.shared

    @State var dropTargeting: Bool = false
    @Namespace private var artNamespace

    // Extra pill width for whichever closed-notch activity is showing.
    private var musicExpand: CGFloat {
        guard vm.status != .opened else { return 0 }
        if battery.activityVisible { return 130 }
        if nowPlaying.hasNowPlaying, nowPlaying.sneakPeekVisible { return 240 }
        return nowPlaying.hasNowPlaying ? 72 : 0
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
        ZStack(alignment: .top) {
            notch
                .zIndex(0)
                .disabled(true)
                .opacity(vm.notchVisible || nowPlaying.hasNowPlaying ? 1 : 0.3)
            // The content stays mounted and its scale/offset/opacity are keyed to
            // the status instead of using an insertion/removal transition, so the
            // close is the exact reverse of the open - one spring drives both
            // directions along the same path.
            VStack(spacing: vm.spacing) {
                NotchHeaderView(vm: vm)
                NotchContentView(vm: vm, artNamespace: artNamespace)
                    .frame(maxHeight: .infinity)
            }
            .padding(vm.spacing)
            .frame(width: vm.notchOpenedSize.width, height: vm.notchOpenedSize.height)
            .scaleEffect(vm.status == .opened ? 1 : 0.05)
            .offset(y: vm.status == .opened ? 0 : -vm.notchOpenedSize.height / 2)
            .opacity(vm.status == .opened ? 1 : 0)
            .allowsHitTesting(vm.status == .opened)
            .zIndex(1)
        }
        .background(dragDetector)
        .animation(vm.animation, value: vm.status)
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        notchFill
            .mask(notchBackgroundMaskGroup)
            .overlay {
                if vm.status != .opened {
                    if battery.activityVisible {
                        notchBatteryOverlay
                    } else if nowPlaying.hasNowPlaying {
                        notchMusicOverlay
                    }
                }
            }
            .frame(
                width: notchSize.width + notchCornerRadius * 2,
                height: notchSize.height
            )
            .shadow(
                color: .black.opacity(([.opened, .popping].contains(vm.status)) ? 1 : 0),
                radius: 16
            )
            .animation(vm.animation, value: nowPlaying.hasNowPlaying)
            .animation(vm.animation, value: nowPlaying.sneakPeekVisible)
            .animation(vm.animation, value: battery.activityVisible)
            .animation(vm.animation, value: vm.glassStyle)
    }

    /// Transient charge indicator shown when the power adapter is plugged in
    /// or removed.
    var notchBatteryOverlay: some View {
        HStack(spacing: 6) {
            Image(systemName: battery.isPluggedIn ? "bolt.fill" : "battery.75percent")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(battery.isPluggedIn ? .green : .yellow)
                .padding(.leading, 10)

            Spacer()

            Text(battery.isPluggedIn ? "Charging" : "On Battery")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            Text("\(battery.levelPercent)%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(battery.isPluggedIn ? .green : .white)
                .padding(.trailing, 10)
        }
        .frame(width: notchSize.width, height: notchSize.height)
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    var notchMusicOverlay: some View {
        HStack(spacing: 8) {
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
            .matchedGeometryEffect(id: "albumArt", in: artNamespace, isSource: vm.status != .opened)
            .padding(.leading, 8)

            if nowPlaying.sneakPeekVisible {
                // Track-change sneak peek: title + artist between art and bars.
                VStack(alignment: .leading, spacing: 0) {
                    MarqueeText(
                        text: nowPlaying.title,
                        font: .system(size: 10, weight: .semibold)
                    )
                    .frame(height: 13)
                    Text(nowPlaying.artist)
                        .font(.system(size: 8.5))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }
                .transition(.opacity)
            } else {
                Spacer(minLength: 0)
            }

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
