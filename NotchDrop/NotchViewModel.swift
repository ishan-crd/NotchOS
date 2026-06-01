import Cocoa
import Combine
import Foundation
import LaunchAtLogin
import SwiftUI

class NotchViewModel: NSObject, ObservableObject {
    var cancellables: Set<AnyCancellable> = []
    let inset: CGFloat

    init(inset: CGFloat = -4) {
        self.inset = inset
        super.init()
        setupCancellables()
    }

    deinit {
        destroy()
    }

    let animation: Animation = .interactiveSpring(
        duration: 0.5,
        extraBounce: 0.1,
        blendDuration: 0.125
    )
    @Published var contentWidth: CGFloat = 600
    let notchOpenedHeight: CGFloat = 160
    let fixedContentWidth: CGFloat = 600
    var notchOpenedSize: CGSize {
        let width = contentType == .normal ? max(contentWidth + 32, 300) : (contentType == .onboarding ? 380 : fixedContentWidth)
        let height: CGFloat = contentType == .onboarding ? 480 : notchOpenedHeight
        return .init(width: width, height: height)
    }
    let dropDetectorRange: CGFloat = 32

    enum Status: String, Codable, Hashable, Equatable {
        case closed
        case opened
        case popping
    }

    enum OpenReason: String, Codable, Hashable, Equatable {
        case click
        case drag
        case boot
        case unknown
    }

    enum GlassStyle: String, Codable, Hashable, Equatable, CaseIterable, Identifiable {
        case flat = "Flat Matte"
        case matte = "Soft Graphite"
        case heavy = "Heavy Glass"

        var id: String { rawValue }
    }

    enum ContentType: Int, Codable, Hashable, Equatable {
        case normal
        case menu
        case settings
        case tray
        case onboarding
    }

    var notchOpenedRect: CGRect {
        .init(
            x: screenRect.origin.x + (screenRect.width - notchOpenedSize.width) / 2,
            y: screenRect.origin.y + screenRect.height - notchOpenedSize.height,
            width: notchOpenedSize.width,
            height: notchOpenedSize.height
        )
    }

    var headlineOpenedRect: CGRect {
        .init(
            x: screenRect.origin.x + (screenRect.width - notchOpenedSize.width) / 2,
            y: screenRect.origin.y + screenRect.height - deviceNotchRect.height,
            width: notchOpenedSize.width,
            height: deviceNotchRect.height
        )
    }

    @Published private(set) var status: Status = .closed
    @Published var openReason: OpenReason = .unknown
    @Published var contentType: ContentType = .normal

    @Published var spacing: CGFloat = 16
    @Published var cornerRadius: CGFloat = 16
    @Published var deviceNotchRect: CGRect = .zero
    @Published var screenRect: CGRect = .zero
    @Published var optionKeyPressed: Bool = false
    @Published var notchVisible: Bool = true

    @PublishedPersist(key: "selectedLanguage", defaultValue: .system)
    var selectedLanguage: Language

    @PublishedPersist(key: "hapticFeedback", defaultValue: true)
    var hapticFeedback: Bool

    @PublishedPersist(key: "onboardingCompleted", defaultValue: false)
    var onboardingCompleted: Bool

    @PublishedPersist(key: "glassStyle", defaultValue: .matte)
    var glassStyle: GlassStyle

    let hapticSender = PassthroughSubject<Void, Never>()

    func notchOpen(_ reason: OpenReason) {
        openReason = reason
        status = .opened
        if !onboardingCompleted && reason == .boot {
            contentType = .onboarding
        } else {
            contentType = reason == .drag ? .tray : .normal
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func notchClose() {
        guard contentType != .onboarding else { return }
        openReason = .unknown
        status = .closed
        contentType = .normal
    }

    func showSettings() {
        contentType = .settings
    }

    func notchPop() {
        openReason = .unknown
        status = .popping
    }
}
