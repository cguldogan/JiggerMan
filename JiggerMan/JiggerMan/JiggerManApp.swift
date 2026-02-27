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
        let isInsertedBinding = Binding<Bool>(
            get: { appState.preferences.showMenuBarIcon },
            set: { newValue in
                if appState.preferences.showMenuBarIcon != newValue {
                    DispatchQueue.main.async {
                        appState.preferences.showMenuBarIcon = newValue
                    }
                }
            }
        )

        MenuBarExtra(isInserted: isInsertedBinding) {
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
