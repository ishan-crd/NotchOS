//
//  NotchHeaderView.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//

import ColorfulX
import SwiftUI

struct NotchHeaderView: View {
    @StateObject var vm: NotchViewModel

    var body: some View {
        HStack(spacing: 12) {
            Text(
                vm.contentType == .settings
                    ? "Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown") (Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"))"
                    : "NotchOS"
            )
            .font(.system(.headline, design: .rounded))
            .contentTransition(.numericText())

            Spacer()

            // Home button (only in settings/tray/menu)
            if vm.contentType == .settings || vm.contentType == .tray || vm.contentType == .menu {
                Button {
                    vm.isEditing = false
                    vm.contentType = .normal
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 11))
                        Text("Home")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.white.opacity(0.08)))
                    .foregroundStyle(.white.opacity(0.6))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // Edit / Done button (only on normal)
            if vm.contentType == .normal {
                Button {
                    withAnimation(vm.animation) {
                        vm.isEditing.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: vm.isEditing ? "checkmark" : "slider.horizontal.3")
                            .font(.system(size: 11, weight: .semibold))
                        Text(vm.isEditing ? "Done" : "Edit")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(vm.isEditing ? .white.opacity(0.9) : .white.opacity(0.08))
                    )
                    .foregroundStyle(vm.isEditing ? .black : .white.opacity(0.6))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // Settings gear
            Button {
                if vm.contentType == .settings {
                    vm.contentType = .normal
                } else {
                    vm.isEditing = false
                    vm.contentType = .settings
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 32, height: 32)
                    .contentShape(Circle())
                    .background(Circle().fill(.white.opacity(0.06)))
            }
            .buttonStyle(.plain)
        }
        .animation(vm.animation, value: vm.contentType)
        .animation(vm.animation, value: vm.isEditing)
    }
}

#Preview {
    NotchHeaderView(vm: .init())
}
