//
//  DebugOverlayWindow.swift
//  BLELamp
//
//  Created by David Price on 4/26/25.
//

import UIKit
import SwiftUI

/**
 * Public functions:
 * - show(content:)
 * - hide()
 */
class DebugOverlayWindow {
    static let s_shared = DebugOverlayWindow()
    private var m_window: UIWindow?

    /// Show the overlay with the given SwiftUI view
    func show<Content: View>(@ViewBuilder content: @escaping () -> Content) {
        guard m_window == nil else { return }
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: content().ignoresSafeArea())
        window.windowLevel = UIWindow.Level.alert + 3 // Highest priority
        window.backgroundColor = .clear
        window.isHidden = false
        window.makeKeyAndVisible()
        m_window = window
    }

    /// Hide the overlay
    func hide() {
        m_window?.isHidden = true
        m_window = nil
    }
} 