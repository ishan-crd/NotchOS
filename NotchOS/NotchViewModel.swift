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
    let fixedContentWidth: CGFloat = 600
    var notchOpenedSize: CGSize {
        if contentType == .normal {
            if activeTab == .tray {
                return .init(width: fixedContentWidth, height: 160)
            }
            switch dashboardLayout {
            case .split:
                let w = max(contentWidth + 32, 300)
                return .init(width: w, height: 160)
            case .grid:
                return .init(width: 520, height: 160)
            case .focus:
                return .init(width: 540, height: 255)
            }
        }
        if contentType == .settings {
            return .init(width: 480, height: 320)
        }
        return .init(width: fixedContentWidth, height: 160)
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

    enum DashboardLayout: String, Codable, Hashable, Equatable, CaseIterable, Identifiable {
        case split = "Split Row"
        case grid = "Compact Grid"
        case focus = "Single Focus"

        var id: String { rawValue }
    }

    enum GlassStyle: String, Codable, Hashable, Equatable, CaseIterable, Identifiable {
        case flat = "Flat Matte"
        case matte = "Soft Graphite"
        case heavy = "Heavy Glass"

        var id: String { rawValue }
    }

    enum Tab: String, Codable, Hashable, Equatable {
        case nook
        case tray
    }

    enum ContentType: Int, Codable, Hashable, Equatable {
        case normal
        case menu
        case settings
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

@PublishedPersist(key: "glassStyle", defaultValue: .flat)
    var glassStyle: GlassStyle

    @PublishedPersist(key: "dashboardLayout", defaultValue: .split)
    var dashboardLayout: DashboardLayout

    @Published var activeTab: Tab = .nook
    @Published var focusPage: Int = 0
    @Published var isEditing: Bool = false

    let hapticSender = PassthroughSubject<Void, Never>()

    func notchOpen(_ reason: OpenReason) {
        openReason = reason
        status = .opened
        contentType = .normal
        activeTab = reason == .drag ? .tray : .nook
        NSApp.activate(ignoringOtherApps: true)
    }

    func notchClose() {
        openReason = .unknown
        status = .closed
        contentType = .normal
        activeTab = .nook
        focusPage = 0
        isEditing = false
    }

    func showSettings() {
        contentType = .settings
    }

    func notchPop() {
        openReason = .unknown
        status = .popping
    }
}
