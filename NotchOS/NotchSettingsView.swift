//
//  NotchSettingsView.swift
//  NotchOS
//
//  Created by 曹丁杰 on 2024/7/29.
//

import LaunchAtLogin
import SwiftUI

struct NotchSettingsView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var tvm: TrayDrop = .shared

    var body: some View {
        VStack(spacing: 10) {
            // MARK: - General
            settingsGroup {
                settingsRow("Language") {
                    Picker(String(), selection: $vm.selectedLanguage) {
                        ForEach(Language.allCases) { language in
                            Text(language.localized).tag(language)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 140)
                }

                Divider().opacity(0.15)

                settingsRow("Launch at Login") {
                    LaunchAtLogin.Toggle { EmptyView() }
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                Divider().opacity(0.15)

                settingsRow("Haptic Feedback") {
                    Toggle(String(), isOn: $vm.hapticFeedback)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                }
            }

            // MARK: - Appearance & Storage
            settingsGroup {
                settingsRow("Notch Style") {
                    Picker(String(), selection: $vm.glassStyle) {
                        ForEach(NotchViewModel.GlassStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 140)
                }

                Divider().opacity(0.15)

                settingsRow("File Storage") {
                    HStack(spacing: 6) {
                        Picker(String(), selection: $tvm.selectedFileStorageTime) {
                            ForEach(TrayDrop.FileStorageTime.allCases) { time in
                                Text(time.localized).tag(time)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 100)

                        if tvm.selectedFileStorageTime == .custom {
                            TextField("", value: $tvm.customStorageTime, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 40)
                            Picker(String(), selection: $tvm.customStorageTimeUnit) {
                                ForEach(TrayDrop.CustomstorageTimeUnit.allCases) { unit in
                                    Text(unit.localized).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 90)
                        }
                    }
                }
            }

            // MARK: - Quit
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit NotchOS")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.red.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.red.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }

    // MARK: - Helpers

    func settingsGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.05))
        )
    }

    func settingsRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            content()
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    NotchSettingsView(vm: .init())
        .padding()
        .frame(width: 480, height: 280, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}
