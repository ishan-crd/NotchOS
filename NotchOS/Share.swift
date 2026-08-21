//
//  Share.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import Cocoa

class Share: NSObject, NSSharingServiceDelegate {
    let files: [URL]
    let serviceName: NSSharingService.Name?

    init(files: [URL], serviceName: NSSharingService.Name? = nil) {
        self.files = files
        self.serviceName = serviceName
        super.init()
    }

    func begin() {
        do {
            try sendEx(files)
        } catch {
            NSAlert.popError(error)
        }
    }

    private func sendEx(_ files: [URL]) throws {
        if let serviceName {
            guard let service = NSSharingService(named: serviceName) else {
                throw NSError(domain: "ShareService", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("Selected sharing service not available", comment: ""),
                ])
            }

            guard service.canPerform(withItems: files) else {
                throw NSError(domain: "ShareService", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("Sharing service cannot perform with given files", comment: ""),
                ])
            }

            service.delegate = self
            service.perform(withItems: files)
        } else {
            // Present the system share sheet
            let picker = NSSharingServicePicker(items: files)
            if let view = NSApp.keyWindow?.contentView {
                picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
            }
        }
    }
}
