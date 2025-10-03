//
//  to_you_App.swift
//  to-you.
//
//  Created by Silver on 10/2/25.
//

import SwiftUI
import Cocoa

@main
struct ToYouApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() } // menubar‑only
    }
}
