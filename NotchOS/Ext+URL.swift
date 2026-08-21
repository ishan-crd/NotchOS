//
//  Ext+URL.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import Cocoa
import Foundation
import QuickLook

extension URL {
    func snapshotPreview() -> NSImage {
        if let preview = QLThumbnailImageCreate(
            kCFAllocatorDefault,
            self as CFURL,
            CGSize(width: 128, height: 128),
            nil
        )?.takeRetainedValue() {
            return NSImage(cgImage: preview, size: .zero)
        }
        return NSWorkspace.shared.icon(forFile: path)
    }
}
