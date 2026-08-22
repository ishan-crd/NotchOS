//
//  Onboarding.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import AppKit
import EventKit
import SwiftUI

// MARK: - Window plumbing

class OnboardingWindowController: NSWindowController {
    static var shared: OnboardingWindowController?

    @Persist(key: "hasCompletedOnboarding", defaultValue: false)
    private static var hasCompletedOnboarding: Bool

    static func presentIfNeeded() {
        guard !hasCompletedOnboarding else { return }
        present()
    }

    static func present() {
        if let shared {
            shared.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 440),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = .black
        window.level = .floating
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.center()

        let controller = OnboardingWindowController(window: window)
        window.contentViewController = NSHostingController(
            rootView: OnboardingRootView { controller.finish() }
        )
        shared = controller
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func finish() {
        Self.hasCompletedOnboarding = true
        window?.orderOut(nil)
        Self.shared = nil
    }
}

// MARK: - Root

private struct OnboardingRootView: View {
    let onFinish: () -> Void

    @State private var page = 0
    private let pageCount = 4

    var body: some View {
        ZStack {
            // Soft animated glow that drifts behind every page.
            DriftingGlow()

            VStack(spacing: 0) {
                ZStack {
                    switch page {
                    case 0: WelcomePage()
                        .transition(pageTransition)
                    case 1: FeaturesPage()
                        .transition(pageTransition)
                    case 2: PermissionsPage()
                        .transition(pageTransition)
                    default: ReadyPage()
                        .transition(pageTransition)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                controls
                    .padding(.horizontal, 32)
                    .padding(.bottom, 26)
            }
        }
        .frame(width: 560, height: 440)
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private var controls: some View {
        HStack {
            // Page dots
            HStack(spacing: 7) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? .white : .white.opacity(0.2))
                        .frame(width: index == page ? 20 : 6, height: 6)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)

            Spacer()

            if page > 0 {
                Button("Back") {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { page -= 1 }
                }
                .buttonStyle(GhostButtonStyle())
                .transition(.opacity)
            }

            Button(page == pageCount - 1 ? String(localized: "Start ✨") : String(localized: "Continue")) {
                if page == pageCount - 1 {
                    onFinish()
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { page += 1 }
                }
            }
            .buttonStyle(GlowButtonStyle())
            .keyboardShortcut(.defaultAction)
        }
        .animation(.easeOut(duration: 0.2), value: page)
    }
}

// MARK: - Pages

private struct WelcomePage: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            BreathingNotch()
                .frame(width: 300, height: 130)
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 8) {
                Text("Meet your notch")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text("That little black island up there?\nIt's about to become the most useful pixel on your Mac.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .offset(y: appeared ? 0 : 16)
            .opacity(appeared ? 1 : 0)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
                appeared = true
            }
        }
    }
}

/// A miniature notch that gently breathes between its closed pill and an
/// expanded panel, with little sparkles orbiting it.
private struct BreathingNotch: View {
    @State private var expanded = false

    var body: some View {
        ZStack(alignment: .top) {
            // Mini "screen"
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(
                    colors: [Color(red: 0.16, green: 0.17, blue: 0.23), Color(red: 0.09, green: 0.09, blue: 0.13)],
                    startPoint: .top, endPoint: .bottom
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )

            // The breathing notch itself
            RoundedRectangle(cornerRadius: expanded ? 12 : 7)
                .fill(.black)
                .frame(width: expanded ? 190 : 84, height: expanded ? 62 : 16)
                .overlay(alignment: .bottomLeading) {
                    if expanded {
                        HStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 26, height: 26)
                            VStack(alignment: .leading, spacing: 3) {
                                Capsule().fill(.white.opacity(0.8)).frame(width: 52, height: 4)
                                Capsule().fill(.white.opacity(0.3)).frame(width: 34, height: 4)
                            }
                            Spacer(minLength: 0)
                            WaveformView(isPlaying: true, color: .pink)
                                .frame(width: 16, height: 10)
                        }
                        .padding(9)
                        .transition(.opacity.combined(with: .scale(scale: 0.7, anchor: .top)))
                    }
                }
                .padding(.top, 6)

            Sparkles()
        }
        .onAppear {
            withAnimation(
                .spring(response: 0.9, dampingFraction: 0.7)
                .repeatForever(autoreverses: true)
                .delay(0.8)
            ) {
                expanded = true
            }
        }
    }
}

/// Tiny twinkling sparkles scattered around the illustration.
private struct Sparkles: View {
    private static let seeds: [(x: CGFloat, y: CGFloat, size: CGFloat, delay: Double)] = [
        (0.08, 0.30, 11, 0.0), (0.90, 0.22, 9, 0.6), (0.16, 0.78, 8, 1.1),
        (0.84, 0.72, 12, 0.3), (0.50, 0.88, 7, 0.9), (0.95, 0.50, 7, 1.4),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<Self.seeds.count, id: \.self) { index in
                let seed = Self.seeds[index]
                Twinkle(delay: seed.delay)
                    .font(.system(size: seed.size))
                    .position(x: geo.size.width * seed.x, y: geo.size.height * seed.y)
            }
        }
    }
}

private struct Twinkle: View {
    let delay: Double
    @State private var on = false

    var body: some View {
        Image(systemName: "sparkle")
            .foregroundStyle(.yellow.opacity(0.9))
            .scaleEffect(on ? 1 : 0.35)
            .opacity(on ? 1 : 0.15)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    on = true
                }
            }
    }
}

private struct FeaturesPage: View {
    @State private var appeared = false

    private static let features: [(icon: String, tint: Color, title: LocalizedStringKey, blurb: LocalizedStringKey)] = [
        ("music.note", .pink, "Now Playing", "Album art, controls and a live waveform for Spotify & Apple Music."),
        ("tray.and.arrow.down.fill", .blue, "File Tray", "Drop files on the notch, AirDrop them anywhere."),
        ("calendar", .red, "Today", "Your events and reminders, one hover away."),
        ("checklist", .green, "Quick Notes", "A tiny checklist that lives in the notch."),
    ]

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 6) {
                Text("Everything, one hover away")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("Rest your cursor on the notch and it blooms open.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<Self.features.count, id: \.self) { index in
                    let feature = Self.features[index]
                    FeatureCard(icon: feature.icon, tint: feature.tint, title: feature.title, blurb: feature.blurb)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.8)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7).delay(0.08 * Double(index) + 0.15),
                            value: appeared
                        )
                }
            }
            .padding(.horizontal, 36)
            Spacer()
        }
        .onAppear { appeared = true }
    }
}

private struct FeatureCard: View {
    let icon: String
    let tint: Color
    let title: LocalizedStringKey
    let blurb: LocalizedStringKey

    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 9).fill(tint.opacity(0.15)))
                .rotationEffect(.degrees(hovering ? -8 : 0))

            Text(title)
                .font(.system(size: 13, weight: .semibold))
            Text(blurb)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(hovering ? 0.09 : 0.05))
        )
        .scaleEffect(hovering ? 1.03 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: hovering)
        .onHover { hovering = $0 }
    }
}

private struct PermissionsPage: View {
    @State private var appeared = false
    @State private var calendarGranted = PermissionsPage.hasCalendarAccess()

    static func hasCalendarAccess() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(macOS 14.0, *) {
            return status == .fullAccess
        }
        return status == .authorized
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 6) {
                Text("A couple of small favors")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("Both optional — NotchOS works fine without them.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
            }

            VStack(spacing: 10) {
                PermissionCard(
                    icon: "calendar",
                    tint: .red,
                    title: "Calendar & Reminders",
                    blurb: "Shows today's events and due reminders in the notch. Nothing leaves your Mac.",
                    granted: calendarGranted
                ) {
                    requestCalendar()
                }

                PermissionCard(
                    icon: "playpause.fill",
                    tint: .pink,
                    title: "Control Spotify & Apple Music",
                    blurb: "macOS will ask the first time you use the player — just tap OK there.",
                    granted: nil,
                    action: nil
                )
            }
            .padding(.horizontal, 60)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }

    private func requestCalendar() {
        let store = EKEventStore()
        let completion: (Bool, Error?) -> Void = { granted, _ in
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    calendarGranted = granted
                }
                if granted { CalendarManager.shared.start() }
            }
        }
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents(completion: completion)
            store.requestFullAccessToReminders { _, _ in }
        } else {
            store.requestAccess(to: .event, completion: completion)
            store.requestAccess(to: .reminder) { _, _ in }
        }
    }
}

private struct PermissionCard: View {
    let icon: String
    let tint: Color
    let title: LocalizedStringKey
    let blurb: LocalizedStringKey
    let granted: Bool?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 9).fill(tint.opacity(0.15)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(blurb)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let granted {
                if granted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                } else if let action {
                    Button("Allow", action: action)
                        .buttonStyle(GlowButtonStyle(compact: true))
                }
            } else {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.05)))
    }
}

private struct ReadyPage: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            ConfettiField()

            VStack(spacing: 14) {
                Spacer()
                Text("🎉")
                    .font(.system(size: 52))
                    .scaleEffect(appeared ? 1 : 0.3)
                    .rotationEffect(.degrees(appeared ? 0 : -30))

                Text("You're all set!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Rest your cursor on the notch and watch it bloom.\nDrag a file onto it. Play a song. Enjoy ✦")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6).delay(0.05)) {
                appeared = true
            }
        }
    }
}

/// Gentle confetti drifting down behind the final page.
private struct ConfettiField: View {
    private static let colors: [Color] = [.pink, .purple, .blue, .mint, .yellow, .orange]
    private struct Seed {
        let x: CGFloat
        let speed: Double
        let size: CGFloat
        let phase: Double
        let colorIndex: Int
    }

    private static let seeds: [Seed] = (0..<26).map { (index: Int) -> Seed in
        let x: Double = (Double(index) * 0.137).truncatingRemainder(dividingBy: 1.0)
        let speed: Double = 24.0 + Double((index * 7) % 30)
        let size: Double = 5.0 + Double(index % 4) * 1.6
        let phase: Double = Double(index) * 1.31
        return Seed(x: CGFloat(x), speed: speed, size: CGFloat(size), phase: phase, colorIndex: index % 6)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
            Canvas { canvas, size in
                let time = context.date.timeIntervalSinceReferenceDate
                for seed in Self.seeds {
                    let fall = (time * seed.speed + seed.phase * 50).truncatingRemainder(dividingBy: Double(size.height + 40)) - 20
                    let sway = sin(time * 1.4 + seed.phase) * 14
                    let rect = CGRect(
                        x: seed.x * size.width + sway,
                        y: fall,
                        width: seed.size,
                        height: seed.size * 0.62
                    )
                    var canvasContext = canvas
                    canvasContext.translateBy(x: rect.midX, y: rect.midY)
                    canvasContext.rotate(by: .radians(time * 1.8 + seed.phase))
                    canvasContext.fill(
                        Path(roundedRect: CGRect(x: -rect.width / 2, y: -rect.height / 2, width: rect.width, height: rect.height), cornerRadius: 1.5),
                        with: .color(Self.colors[seed.colorIndex].opacity(0.75))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Chrome

/// A slow, soft color glow that drifts behind the pages.
private struct DriftingGlow: View {
    @State private var move = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.16))
                .frame(width: 340, height: 340)
                .blur(radius: 70)
                .offset(x: move ? -140 : 120, y: move ? -110 : -30)
            Circle()
                .fill(Color.pink.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: move ? 150 : -110, y: move ? 120 : 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                move = true
            }
        }
    }
}

private struct GlowButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 11 : 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, compact ? 12 : 20)
            .padding(.vertical, compact ? 5 : 9)
            .background(Capsule().fill(.white))
            .shadow(color: .white.opacity(0.25), radius: configuration.isPressed ? 2 : 10)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

private struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.55))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}
