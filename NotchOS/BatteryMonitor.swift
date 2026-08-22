//
//  BatteryMonitor.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import Combine
import Foundation
import IOKit.ps

/// Watches the battery via IOKit power-source notifications and publishes a
/// transient "live activity" for the closed notch whenever the charger is
/// plugged in or removed.
class BatteryMonitor: ObservableObject {
    static let shared = BatteryMonitor()

    @Published private(set) var levelPercent: Int = 100
    @Published private(set) var isCharging: Bool = false
    @Published private(set) var isPluggedIn: Bool = false

    /// True while the plug/unplug activity should be visible in the pill.
    @Published private(set) var activityVisible: Bool = false

    private var runLoopSource: CFRunLoopSource?
    private var hideWorkItem: DispatchWorkItem?
    private var lastPluggedIn: Bool?

    private init() {}

    func start() {
        readPowerState(showActivity: false)

        let callback: IOPowerSourceCallbackType = { context in
            guard let context else { return }
            let monitor = Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async { monitor.readPowerState(showActivity: true) }
        }
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let source = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() else { return }
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
    }

    private func readPowerState(showActivity: Bool) {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef]
        else { return }

        for source in list {
            guard let info = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any],
                  let capacity = info[kIOPSCurrentCapacityKey] as? Int,
                  let max = info[kIOPSMaxCapacityKey] as? Int, max > 0
            else { continue }

            let charging = info[kIOPSIsChargingKey] as? Bool ?? false
            let plugged = (info[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue

            levelPercent = capacity * 100 / max
            isCharging = charging

            let pluggedChanged = lastPluggedIn != nil && lastPluggedIn != plugged
            lastPluggedIn = plugged
            isPluggedIn = plugged

            if showActivity, pluggedChanged {
                presentActivity()
            }
            break
        }
    }

    private func presentActivity() {
        hideWorkItem?.cancel()
        activityVisible = true
        let workItem = DispatchWorkItem { [weak self] in
            self?.activityVisible = false
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }
}
