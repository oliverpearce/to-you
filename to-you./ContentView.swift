//
//  ContentView.swift
//  to-you.
//
//  Created by Silver on 10/2/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var model = AppModel()

    var body: some View {
        TimerPopoverView(
            model: model,
            showHUD: { print("showHUD called") },
            hideHUD: { print("hideHUD called") }
        )
        .padding()
    }
}
