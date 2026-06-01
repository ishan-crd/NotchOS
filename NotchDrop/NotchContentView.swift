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

struct TrayDropContentView: View {
    @StateObject var vm: NotchViewModel

    var body: some View {
        HStack(spacing: vm.spacing) {
            ShareView(vm: vm, type: .airdrop)
            TrayView(vm: vm)
        }
    }
}

struct NotchContentView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var tvm = TrayDrop.shared

    var trayButton: some View {
        Button {
            vm.contentType = .tray
        } label: {
            RoundedRectangle(cornerRadius: vm.cornerRadius)
                .fill(.white.opacity(0.08))
                .overlay {
                    VStack(spacing: 6) {
                        ZStack {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .font(.system(size: 20))
                            if !tvm.isEmpty {
                                Text("\(tvm.items.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(.blue))
                                    .offset(x: 14, y: -10)
                            }
                        }
                        Text(NSLocalizedString("Tray", comment: ""))
                            .font(.system(.caption, design: .rounded))
                    }
                }
                .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        ZStack {
            switch vm.contentType {
            case .normal:
                HStack(spacing: vm.spacing) {
                    MediaPlayerView(vm: vm)
                    CalendarView(vm: vm)
                    trayButton
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            case .tray:
                TrayDropContentView(vm: vm)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            case .menu:
                NotchMenuView(vm: vm)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            case .settings:
                NotchSettingsView(vm: vm)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .animation(vm.animation, value: vm.contentType)
    }
}

#Preview {
    NotchContentView(vm: .init())
        .padding()
        .frame(width: 600, height: 150, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}
