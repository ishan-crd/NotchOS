//
//  Ext+NSImage.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import Cocoa

extension NSImage {
    var pngRepresentation: Data {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .init()
        }
        let imageRep = NSBitmapImageRep(cgImage: cgImage)
        imageRep.size = size
        return imageRep.representation(using: .png, properties: [:]) ?? .init()
    }
}
