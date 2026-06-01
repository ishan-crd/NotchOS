//
//  NotchHeaderView.swift
//  NotchOS
//
//  Created by 秋星桥 on 2024/7/7.
//

import SwiftUI

struct NotchHeaderView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var tvm = TrayDrop.shared

    var body: some View {
        HStack {
            // MARK: - Leading: tabs or version text
            leadingContent
            Spacer(minLength: 0)
            // MARK: - Trailing: action buttons
            trailingContent
        }
    }

    // MARK: - Leading

    @ViewBuilder
    var leadingContent: some View {
        switch vm.contentType {
        case .normal:
            HStack(spacing: 6) {
                tabPill(icon: "star.fill", label: "Notch", tab: .nook)
                tabPill(icon: "tray.fill", label: "Tray", tab: .tray, badge: tvm.isEmpty ? 0 : tvm.items.count)
            }
        case .settings:
            Text("Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown") (Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"))")
                .font(.system(.headline, design: .rounded))
        default:
            EmptyView()
        }
    }

    // MARK: - Trailing

    @ViewBuilder
    var trailingContent: some View {
        HStack(spacing: 8) {
            if vm.contentType == .settings || vm.contentType == .menu {
                homeButton
            }
            if vm.contentType == .normal && vm.activeTab == .nook {
                editButton
            }
            settingsButton
        }
    }

    // MARK: - Buttons

    var homeButton: some View {
        Button {
            vm.isEditing = false
            withAnimation(vm.animation) {
                vm.contentType = .normal
            }
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

    var editButton: some View {
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

    var settingsButton: some View {
        Button {
            withAnimation(vm.animation) {
                if vm.contentType == .settings {
                    vm.contentType = .normal
                } else {
                    vm.isEditing = false
                    vm.contentType = .settings
                }
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

    // MARK: - Tab Pill

    func tabPill(icon: String, label: String, tab: NotchViewModel.Tab, badge: Int = 0) -> some View {
        Button {
            withAnimation(vm.animation) {
                vm.isEditing = false
                vm.activeTab = tab
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(.blue))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(vm.activeTab == tab ? .white.opacity(0.12) : .white.opacity(0.04))
            )
            .foregroundStyle(vm.activeTab == tab ? .white : .white.opacity(0.4))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NotchHeaderView(vm: .init())
}
