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
            Toggle("Simulate Activity", isOn: $appState.manualSimulateActivity)
            Divider()
            if #available(macOS 14.0, *) {
                SettingsLink {
                    Text("Open Settings")
                }
            } else {
                Button("Open Settings") {
                    NSApp.activate(ignoringOtherApps: true)
                    if #available(macOS 13.0, *) {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } else {
                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                    }
                }
            }
            Button("Quit JiggerMan") {
                NSApp.terminate(nil)
            }
        } label: {
            Image(systemName: appState.menuBarIconName)
        }
        .environmentObject(appState)

        Settings {
            ContentView()
                .environmentObject(appState)
        }
    }
}
