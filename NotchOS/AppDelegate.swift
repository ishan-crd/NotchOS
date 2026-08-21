//
//  AppDelegate.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import AppKit
import Cocoa
import LaunchAtLogin

class AppDelegate: NSObject, NSApplicationDelegate {
    var isFirstOpen = true
    var isLaunchedAtLogin = false
    var mainWindowController: NotchWindowController?

    var timer: Timer?

    func applicationDidFinishLaunching(_: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(rebuildApplicationWindows),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NSApp.setActivationPolicy(.accessory)

        isLaunchedAtLogin = LaunchAtLogin.wasLaunchedAtLogin

        _ = EventMonitors.shared
        // Keeps the panel key while open. Stale-instance cleanup happens once at
        // launch in main.swift, so no per-tick disk I/O is needed here.
        let timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            self?.makeKeyAndVisibleIfNeeded()
        }
        self.timer = timer

        rebuildApplicationWindows()
    }

    func applicationWillTerminate(_: Notification) {
        try? FileManager.default.removeItem(at: temporaryDirectory)
        try? FileManager.default.removeItem(at: pidFile)
    }

    func findScreenFitsOurNeeds() -> NSScreen? {
        if let screen = NSScreen.buildin, screen.notchSize != .zero { return screen }
        return .main
    }

    private var lastScreenSignature: String?

    @objc func rebuildApplicationWindows() {
        defer { isFirstOpen = false }
        guard let mainScreen = findScreenFitsOurNeeds() else {
            mainWindowController?.destroy()
            mainWindowController = nil
            lastScreenSignature = nil
            return
        }
        // macOS fires didChangeScreenParametersNotification for many unrelated
        // reasons; only tear down and rebuild the window when the target screen
        // actually changed, so the notch doesn't vanish mid-use.
        let signature = "\(mainScreen.frame)|\(mainScreen.notchSize)"
        if mainWindowController != nil, signature == lastScreenSignature { return }
        lastScreenSignature = signature

        if let mainWindowController {
            mainWindowController.destroy()
        }
        mainWindowController = nil
        mainWindowController = .init(screen: mainScreen)
        if isFirstOpen, !isLaunchedAtLogin {
            mainWindowController?.openAfterCreate = true
        }
    }

    func makeKeyAndVisibleIfNeeded() {
        guard let controller = mainWindowController,
              let window = controller.window,
              let vm = controller.vm,
              vm.status == .opened
        else { return }
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        guard let controller = mainWindowController,
              let vm = controller.vm
        else { return true }
        vm.notchOpen(.click)
        return true
    }
}
