//
//  BLELampApp.swift
//  BLELamp
//
//  Created by David Price on 4/26/25.
//

import SwiftUI

@main
struct BLELampApp: App {
    init() {
        if Globals.g_debugMode {
            DebugOverlayWindow.s_shared.show {
                LadybugOverlayView()
            }
        }
        Logger.shared.log(level: .debug, message: "App Start")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
