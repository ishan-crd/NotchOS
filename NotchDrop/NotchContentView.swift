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
        VStack(spacing: 10) {
            MediaPlayerView(vm: vm)
            CalendarView(vm: vm)
                .frame(height: 70)
        }
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
            VStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.2)).frame(height: 18)
                RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.12)).frame(height: 10)
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

#Preview {
    NotchContentView(vm: .init())
        .padding()
        .frame(width: 600, height: 150, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}
