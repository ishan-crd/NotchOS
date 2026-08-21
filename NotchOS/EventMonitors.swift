//
//  EventMonitors.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import Cocoa
import Combine

class EventMonitors {
    static let shared = EventMonitors()

    private var mouseMoveEvent: EventMonitor!
    private var mouseDownEvent: EventMonitor!
    private var optionKeyPressEvent: EventMonitor!

    let mouseLocation: CurrentValueSubject<NSPoint, Never> = .init(.zero)
    let mouseDown: PassthroughSubject<Void, Never> = .init()
    let optionKeyPress: CurrentValueSubject<Bool, Never> = .init(false)

    private init() {
        mouseMoveEvent = EventMonitor(mask: .mouseMoved) { [weak self] _ in
            guard let self else { return }
            let mouseLocation = NSEvent.mouseLocation
            self.mouseLocation.send(mouseLocation)
        }
        mouseMoveEvent.start()

        mouseDownEvent = EventMonitor(mask: .leftMouseDown) { [weak self] _ in
            guard let self else { return }
            mouseDown.send()
        }
        mouseDownEvent.start()

        optionKeyPressEvent = EventMonitor(mask: .flagsChanged) { [weak self] event in
            guard let self else { return }
            if event?.modifierFlags.contains(.option) == true {
                optionKeyPress.send(true)
            } else {
                optionKeyPress.send(false)
            }
        }
        optionKeyPressEvent.start()
    }
}
