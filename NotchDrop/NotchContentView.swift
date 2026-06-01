//
//  NotchContentView.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//  Last Modified by 冷月 on 2025/5/5.
//

import ColorfulX
import SwiftUI
import UniformTypeIdentifiers

private struct ContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct TrayDropContentView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var tvm = TrayDrop.shared

    var body: some View {
        HStack(spacing: vm.spacing) {
            trayAirdropButton
            TrayView(vm: vm)
        }
    }

    var trayAirdropButton: some View {
        RoundedRectangle(cornerRadius: vm.cornerRadius)
            .fill(.white.opacity(0.08))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "airplayaudio")
                    Text(NSLocalizedString("AirDrop", comment: ""))
                }
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(tvm.isEmpty ? .white.opacity(0.3) : .white)
            }
            .aspectRatio(1, contentMode: .fit)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !tvm.isEmpty else { return }
                let urls = tvm.items.map(\.storageURL)
                let share = Share(files: urls, serviceName: .sendViaAirDrop)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    vm.notchClose()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    share.begin()
                }
            }
    }
}

struct NotchContentView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var tvm = TrayDrop.shared

    // MARK: - Layout Views

    var splitLayout: some View {
        HStack(spacing: vm.spacing) {
            MediaPlayerView(vm: vm)
                .frame(width: 240)
            CalendarView(vm: vm)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    var gridLayout: some View {
        HStack(spacing: 10) {
            MediaPlayerView(vm: vm)
            CalendarView(vm: vm)
        }
    }

    var focusLayout: some View {
        FocusCarouselView(vm: vm)
    }

    // MARK: - Edit Mode Overlay

    var editOverlay: some View {
        VStack(spacing: 12) {
            Text("Dashboard Layout")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
                .textCase(.uppercase)
                .tracking(0.6)

            HStack(spacing: 10) {
                ForEach(NotchViewModel.DashboardLayout.allCases) { layout in
                    layoutOption(layout)
                }
            }
        }
    }

    func layoutOption(_ layout: NotchViewModel.DashboardLayout) -> some View {
        let selected = vm.dashboardLayout == layout
        return Button {
            withAnimation(vm.animation) {
                vm.dashboardLayout = layout
            }
        } label: {
            VStack(spacing: 6) {
                layoutIcon(layout)
                    .frame(width: 60, height: 40)
                Text(layout.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(selected ? .white : .white.opacity(0.4))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? .white.opacity(0.1) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(selected ? .white.opacity(0.3) : .white.opacity(0.06), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func layoutIcon(_ layout: NotchViewModel.DashboardLayout) -> some View {
        switch layout {
        case .split:
            HStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.2)).frame(width: 28, height: 28)
                RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.15)).frame(width: 28, height: 28)
            }
        case .grid:
            HStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.2))
                RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.15))
            }
            .frame(height: 28)
        case .focus:
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.2)).frame(width: 36, height: 28)
                RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.08)).frame(width: 14, height: 28)
            }
        }
    }

    var body: some View {
        ZStack {
            switch vm.contentType {
            case .normal:
                Group {
                    switch vm.activeTab {
                    case .nook:
                        Group {
                            if vm.isEditing {
                                editOverlay
                            } else {
                                switch vm.dashboardLayout {
                                case .split: splitLayout
                                case .grid: gridLayout
                                case .focus: focusLayout
                                }
                            }
                        }
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: ContentWidthKey.self, value: geo.size.width)
                        })
                        .onPreferenceChange(ContentWidthKey.self) { width in
                            if width > 0, !vm.isEditing { vm.contentWidth = width }
                        }
                    case .tray:
                        TrayDropContentView(vm: vm)
                    }
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            case .menu:
                NotchMenuView(vm: vm)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            case .settings:
                NotchSettingsView(vm: vm)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            case .onboarding:
                OnboardingView(vm: vm)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .animation(vm.animation, value: vm.contentType)
        .animation(vm.animation, value: vm.activeTab)
    }
}

// MARK: - Focus Carousel

struct FocusCarouselView: View {
    @StateObject var vm: NotchViewModel
    @State private var dragOffset: CGFloat = 0

    private let pageCount = 2

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let pageWidth = geo.size.width
                let currentOffset = -CGFloat(vm.focusPage) * pageWidth + dragOffset

                HStack(spacing: 0) {
                    FocusMediaPlayerView(vm: vm)
                        .frame(width: pageWidth, height: geo.size.height)
                    CalendarView(vm: vm)
                        .frame(width: pageWidth, height: geo.size.height)
                }
                .offset(x: currentOffset)
                .animation(vm.animation, value: vm.focusPage)
                .contentShape(Rectangle())
                .highPriorityGesture(
                    DragGesture(minimumDistance: 15)
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = pageWidth * 0.2
                            let predicted = value.predictedEndTranslation.width
                            withAnimation(vm.animation) {
                                if predicted < -threshold, vm.focusPage < pageCount - 1 {
                                    vm.focusPage += 1
                                } else if predicted > threshold, vm.focusPage > 0 {
                                    vm.focusPage -= 1
                                }
                                dragOffset = 0
                            }
                        }
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius))

            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<pageCount, id: \.self) { i in
                    Capsule()
                        .fill(i == vm.focusPage ? .white.opacity(0.8) : .white.opacity(0.15))
                        .frame(width: i == vm.focusPage ? 16 : 5, height: 5)
                }
            }
        }
    }
}

// MARK: - Focus Media Player (expanded single-card view)

struct FocusMediaPlayerView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject private var nowPlaying = NowPlayingManager.shared

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }

    var body: some View {
        Group {
            if nowPlaying.hasNowPlaying {
                playerContent
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var emptyState: some View {
        RoundedRectangle(cornerRadius: vm.cornerRadius)
            .strokeBorder(style: StrokeStyle(lineWidth: 4, dash: [10]))
            .foregroundStyle(.white.opacity(0.1))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "music.note")
                    Text("No Media Playing")
                        .font(.system(.headline, design: .rounded))
                }
            }
    }

    var playerContent: some View {
        VStack(spacing: 0) {
            // Top section: artwork + track info
            HStack(spacing: 14) {
                artworkView
                trackInfo
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)

            Spacer(minLength: 6)

            // Progress bar
            progressBar
                .padding(.horizontal, 14)

            Spacer(minLength: 6)

            // Controls
            controls
                .padding(.bottom, 8)
        }
    }

    var artworkView: some View {
        Group {
            if let artwork = nowPlaying.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.white.opacity(0.1)
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(width: 90, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var trackInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(nowPlaying.title)
                .font(.system(size: 17, weight: .bold))
                .lineLimit(1)

            Text(nowPlaying.album)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)

            Text(nowPlaying.artist)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var progressBar: some View {
        VStack(spacing: 2) {
            GeometryReader { geo in
                let progress = nowPlaying.duration > 0 ? min(nowPlaying.position / nowPlaying.duration, 1.0) : 0

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(height: 3)
                    Capsule()
                        .fill(.white.opacity(0.9))
                        .frame(width: geo.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)

            HStack {
                Text(formatTime(nowPlaying.position))
                Spacer()
                Text(formatTime(nowPlaying.duration))
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.35))
        }
    }

    var controls: some View {
        HStack(spacing: 28) {
            Button(action: { nowPlaying.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 15))
            }
            .buttonStyle(.plain)

            Button(action: { nowPlaying.togglePlayPause() }) {
                Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22))
            }
            .buttonStyle(.plain)

            Button(action: { nowPlaying.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 15))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
    }
}

#Preview {
    NotchContentView(vm: .init())
        .padding()
        .frame(width: 600, height: 150, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}
