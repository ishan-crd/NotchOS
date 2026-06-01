//
//  NotchView.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//

import SwiftUI

struct NotchView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject private var nowPlaying = NowPlayingManager.shared

    @State var dropTargeting: Bool = false

    private var musicExpand: CGFloat {
        nowPlaying.hasNowPlaying && vm.status == .closed ? 80 : 0
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
            Group {
                if vm.status == .opened {
                    VStack(spacing: vm.contentType == .onboarding ? 0 : vm.spacing) {
                        if vm.contentType != .onboarding {
                            NotchHeaderView(vm: vm)
                        }
                        NotchContentView(vm: vm)
                            .frame(maxHeight: .infinity)
                    }
                    .padding(vm.contentType == .onboarding ? 0 : vm.spacing)
                    .frame(width: vm.notchOpenedSize.width, height: vm.notchOpenedSize.height)
                    .zIndex(1)
                }
            }
            .transition(
                .scale.combined(
                    with: .opacity
                ).combined(
                    with: .offset(y: -vm.notchOpenedSize.height / 2)
                ).animation(vm.animation)
            )
        }
        .background(dragDetector)
        .animation(vm.animation, value: vm.status)
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    var notchBackground: some ShapeStyle {
        if vm.status != .opened {
            return AnyShapeStyle(.black)
        }
        switch vm.glassStyle {
        case .flat:
            return AnyShapeStyle(Color(red: 0.027, green: 0.027, blue: 0.031))
        case .matte:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(red: 0.075, green: 0.075, blue: 0.086), Color(red: 0.031, green: 0.031, blue: 0.039)],
                    startPoint: .top, endPoint: .bottom
                )
            )
        case .heavy:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(red: 0.086, green: 0.086, blue: 0.102).opacity(0.86), Color(red: 0.031, green: 0.031, blue: 0.039).opacity(0.92)],
                    startPoint: .top, endPoint: .bottom
                )
            )
        }
    }

    var notch: some View {
        ZStack {
            // Heavy glass: material layer behind the color, both masked together
            if vm.status == .opened && vm.glassStyle == .heavy {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask(notchBackgroundMaskGroup)
            }
            Rectangle()
                .foregroundStyle(notchBackground)
                .mask(notchBackgroundMaskGroup)
        }
        .overlay {
            if nowPlaying.hasNowPlaying && vm.status != .opened {
                notchMusicOverlay
            }
        }
        .overlay {
            if vm.status == .opened {
                RoundedRectangle(cornerRadius: notchCornerRadius)
                    .strokeBorder(.white.opacity(0.06), lineWidth: 0.5)
                    .padding(.top, -0.5)
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
            .frame(width: 22, height: 22)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .padding(.leading, 8)

            Spacer()

            // Waveform bars on the right
            WaveformView(isPlaying: nowPlaying.isPlaying)
                .frame(width: 28, height: 16)
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
            .overlay {
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .frame(width: notchCornerRadius, height: notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topTrailingRadius: notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: notchCornerRadius + vm.spacing,
                            height: notchCornerRadius + vm.spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -notchCornerRadius - vm.spacing + 1, y: -0.5)
            }
            .overlay {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .frame(width: notchCornerRadius, height: notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topLeadingRadius: notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: notchCornerRadius + vm.spacing,
                            height: notchCornerRadius + vm.spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: notchCornerRadius + vm.spacing - 1, y: -0.5)
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
