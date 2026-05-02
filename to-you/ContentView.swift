//
//  ContentView.swift
//  to-you.

import SwiftUI

struct ContentView: View {
    @StateObject var model = AppModel()

    var body: some View {
        TimerPopoverView(model: model, openSettings: {}, closePopover: {}, toggleHUD: {})
            .padding()
    }
}
