//
//  QuickLookPreviewer.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import AppKit
import Quartz

/// Presents the system Quick Look panel for tray files.
class QuickLookPreviewer: NSResponder, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = QuickLookPreviewer()

    private var urls: [URL] = []

    func preview(_ urls: [URL]) {
        self.urls = urls
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - QLPreviewPanelDataSource

    func numberOfPreviewItems(in _: QLPreviewPanel!) -> Int {
        urls.count
    }

    func previewPanel(_: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        urls[index] as NSURL
    }
}
