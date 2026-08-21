//
//  NotchViewController.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import AppKit
import Cocoa
import SwiftUI

class NotchViewController: NSHostingController<NotchView> {
    init(_ vm: NotchViewModel) {
        super.init(rootView: .init(vm: vm))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
