//
//  NotchViewModel+Events.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import Cocoa
import Combine
import Foundation
import SwiftUI

extension NotchViewModel {
    func setupCancellables() {
        let events = EventMonitors.shared
        events.mouseDown
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let mouseLocation: NSPoint = NSEvent.mouseLocation
                switch status {
                case .opened:
                    // touch outside, close
                    if !notchOpenedRect.contains(mouseLocation) {
                        notchClose()
                        // click where user open the panel
                    } else if deviceNotchRect.insetBy(dx: inset, dy: inset).contains(mouseLocation) {
                        notchClose()
                    }
                case .closed, .popping:
                    // touch inside, open
                    if deviceNotchRect.insetBy(dx: inset, dy: inset).contains(mouseLocation) {
                        notchOpen(.click)
                    }
                }
            }
            .store(in: &cancellables)

        events.optionKeyPress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] input in
                guard let self else { return }
                optionKeyPressed = input
            }
            .store(in: &cancellables)

        // NSEvent monitor callbacks already arrive on the main thread; this fires on
        // every mouse move, so avoid an extra async hop per event and bail out early
        // when no state transition is possible.
        events.mouseLocation
            .sink { [weak self] mouseLocation in
                guard let self else { return }
                if status == .opened {
                    scheduleAutoCloseIfNeeded(mouseLocation: mouseLocation)
                    return
                }
                let aboutToOpen = deviceNotchRect.insetBy(dx: inset, dy: inset).contains(mouseLocation)
                if status == .closed, aboutToOpen { notchPop() }
                if status == .popping, !aboutToOpen { notchClose() }
            }
            .store(in: &cancellables)

        $status
            .filter { $0 != .closed }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                withAnimation { self?.notchVisible = true }
            }
            .store(in: &cancellables)

        $status
            .filter { $0 == .popping }
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] _ in
                guard NSEvent.pressedMouseButtons == 0 else { return }
                self?.hapticSender.send()
            }
            .store(in: &cancellables)

        hapticSender
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] _ in
                guard self?.hapticFeedback ?? false else { return }
                NSHapticFeedbackManager.defaultPerformer.perform(
                    .levelChange,
                    performanceTime: .now
                )
            }
            .store(in: &cancellables)

        $status
            .debounce(for: 0.5, scheduler: DispatchQueue.global())
            .filter { $0 == .closed }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                withAnimation {
                    self?.notchVisible = false
                }
            }
            .store(in: &cancellables)

        $selectedLanguage
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] output in
                self?.notchClose()
                output.apply()
            }
            .store(in: &cancellables)
    }

    /// Closes the opened panel after the cursor has stayed outside it for a
    /// grace period; moving back inside cancels the pending close.
    private func scheduleAutoCloseIfNeeded(mouseLocation: NSPoint) {
        // A margin around the panel so grazing the edge doesn't count as leaving.
        let hoverRect = notchOpenedRect.insetBy(dx: -8, dy: -8)
        if hoverRect.contains(mouseLocation) {
            cancelAutoClose()
            return
        }
        guard autoCloseWorkItem == nil else { return }
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, status == .opened else { return }
            autoCloseWorkItem = nil
            // Re-check on fire: the cursor may have come back without moving
            // through an event we saw, or the panel may have resized under it.
            if !notchOpenedRect.insetBy(dx: -8, dy: -8).contains(NSEvent.mouseLocation) {
                notchClose()
            }
        }
        autoCloseWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    func destroy() {
        cancelAutoClose()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
