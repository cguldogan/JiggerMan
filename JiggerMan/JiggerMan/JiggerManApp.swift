//
//  JiggerManApp.swift
//  JiggerMan
//
//  Created by Can GULDOGAN on 23/12/2025.
//

import AppKit
import SwiftUI

@main
struct JiggerManApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(appState: appState)
        } label: {
            Image(systemName: appState.menuBarIconName)
        }
        .menuBarExtraStyle(.window)
        .environmentObject(appState)

        Settings {
            ContentView()
                .environmentObject(appState)
        }
    }
}
