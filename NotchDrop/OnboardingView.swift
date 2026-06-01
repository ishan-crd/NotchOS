import SwiftUI

struct OnboardingView: View {
    @StateObject var vm: NotchViewModel
    @State private var step: Int = 1
    @State private var widgetPicks: [String: Bool] = [
        "music": true, "calendar": true, "weather": true,
        "focus": false, "notes": false, "controls": true
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Content area
            Group {
                switch step {
                case 1: welcomeStep
                case 2: widgetsStep
                case 3: permissionsStep
                default: doneStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Footer: dots + button
            VStack(spacing: 14) {
                // Page dots
                HStack(spacing: 6) {
                    ForEach(0..<4) { i in
                        Capsule()
                            .fill(i == step - 1 ? .white.opacity(0.9) : .white.opacity(0.2))
                            .frame(width: i == step - 1 ? 18 : 6, height: 6)
                            .animation(.spring(duration: 0.3), value: step)
                    }
                }

                // Action button
                Button {
                    handleAction()
                } label: {
                    Text(buttonLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white.opacity(0.92))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
            .padding(.top, 14)
        }
        .animation(vm.animation, value: step)
    }

    // MARK: - Step 1: Welcome

    var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Mini notch illustration
            HStack(spacing: 8) {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 6, height: 6)
                WaveformView(isPlaying: true)
                    .frame(width: 24, height: 11)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
                    )
            )
            .padding(.bottom, 26)

            Text("NotchOS")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))

            Text("The space above your screen, finally put to work. A living hub for everything you do.")
                .font(.system(size: 13.5))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 10)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Step 2: Pick Widgets

    var widgetsStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Build your Notch Home")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))

            Text("Pick the widgets you want. Rearrange anytime.")
                .font(.system(size: 12.5))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 6)
                .padding(.bottom, 18)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(Array(widgetOptions), id: \.key) { key, label in
                    widgetTile(key: key, label: label)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    var widgetOptions: [(key: String, label: String)] {
        [("music", "Music"), ("calendar", "Calendar"), ("weather", "Weather"),
         ("focus", "Focus"), ("notes", "Notes"), ("controls", "Controls")]
    }

    func widgetTile(key: String, label: String) -> some View {
        let selected = widgetPicks[key] ?? false
        return Button {
            widgetPicks[key] = !selected
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(selected ? .white.opacity(0.9) : .clear)
                    .overlay {
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.black)
                        }
                    }
                    .overlay {
                        if !selected {
                            Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1.5)
                        }
                    }
                    .frame(width: 18, height: 18)

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()
            }
            .padding(.horizontal, 13)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? .white.opacity(0.07) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(selected ? .white.opacity(0.4) : .white.opacity(0.08), lineWidth: selected ? 1 : 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 3: Permissions

    var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("A couple of permissions")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))

            Text("NotchOS only uses what it needs to run.")
                .font(.system(size: 12.5))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 6)
                .padding(.bottom, 18)

            VStack(spacing: 10) {
                permissionRow(
                    icon: "accessibility",
                    title: "Accessibility",
                    subtitle: "Expand & morph the notch",
                    enabled: true
                )
                permissionRow(
                    icon: "doc.on.doc",
                    title: "Files & AirDrop",
                    subtitle: "For the drop tray",
                    enabled: true
                )
                permissionRow(
                    icon: "music.note",
                    title: "Media & Now Playing",
                    subtitle: "Show what's playing",
                    enabled: false
                )
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    func permissionRow(icon: String, title: String, subtitle: String, enabled: Bool) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 9)
                .fill(.white.opacity(0.06))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.8))
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()

            // Toggle visual
            Capsule()
                .fill(enabled ? Color(red: 0.21, green: 0.83, blue: 0.6) : .white.opacity(0.1))
                .frame(width: 42, height: 25)
                .overlay(alignment: enabled ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .padding(2.5)
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.03))
        )
    }

    // MARK: - Step 4: Done

    var doneStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Green checkmark circle
            Circle()
                .fill(Color(red: 0.21, green: 0.83, blue: 0.6).opacity(0.14))
                .frame(width: 76, height: 76)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(Color(red: 0.21, green: 0.83, blue: 0.6))
                }
                .padding(.bottom, 22)

            Text("You're all set")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))

            Text("Push your pointer to the top of the screen to open your Notch Home.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 10)
                .padding(.horizontal, 28)

            Spacer()
        }
    }

    // MARK: - Helpers

    var buttonLabel: String {
        switch step {
        case 1: "Get started"
        case 2: "Continue"
        case 3: "Grant & continue"
        default: "Open my Notch"
        }
    }

    func handleAction() {
        if step < 4 {
            withAnimation(vm.animation) {
                step += 1
            }
        } else {
            vm.onboardingCompleted = true
            vm.contentType = .normal
        }
    }
}
