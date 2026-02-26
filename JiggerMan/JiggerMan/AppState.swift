//
//  AppState.swift
//  JiggerMan
//
//  Created by Can GULDOGAN on 23/12/2025.
//

import AppKit
import Combine
import Foundation

final class AppState: ObservableObject {
    @Published var manualSimulateActivity: Bool {
        didSet {
            if manualSimulateActivity && !oldValue {
                if !checkAccessibilityPermissions() {
                    DispatchQueue.main.async {
                        self.manualSimulateActivity = false
                        self.openAccessibilitySettings()
                    }
                    return
                }
            }
            scheduleEvaluation(reason: "Manual")
        }
    }
    @Published var preferences: Preferences {
        didSet {
            if oldValue.launchAtLogin != preferences.launchAtLogin {
                LaunchAtLoginManager.shared.setEnabled(preferences.launchAtLogin)
            }
            if oldValue.logRetentionDays != preferences.logRetentionDays {
                LogStore.shared.prune(olderThanDays: preferences.logRetentionDays)
            }
            if oldValue.showInDock != preferences.showInDock {
                NSApp.setActivationPolicy(preferences.showInDock ? .regular : .accessory)
                if preferences.showInDock {
                    // Explicitly set the dock icon to ensure it appears
                    NSApp.applicationIconImage = NSImage(named: "DockIcon")
                    // When switching to regular, we might want to activate to show the dock icon bouncing/appearing
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            scheduleEvaluation(reason: "Preferences")
            persist()
        }
    }
    @Published private(set) var isActive = false
    @Published private(set) var statusText = "Off"

    private let jiggleManager = JiggleManager()
    private var lastActive = false

    init() {
        if let snapshot = PersistenceStore.shared.load() {
            var loadedPreferences = snapshot.preferences
            // Migration: If interval is 60 (old default), change to 5 (new default)
            if loadedPreferences.jiggleInterval == 60.0 {
                loadedPreferences.jiggleInterval = 5.0
            }
            self.preferences = loadedPreferences
            self.manualSimulateActivity = snapshot.manualSimulateActivity
        } else {
            self.preferences = .default
            self.manualSimulateActivity = false
        }

        if manualSimulateActivity && !checkAccessibilityPermissions() {
            self.manualSimulateActivity = false
        }

        LogStore.shared.prune(olderThanDays: preferences.logRetentionDays)

        // Apply initial dock state
        NSApp.setActivationPolicy(preferences.showInDock ? .regular : .accessory)
        if preferences.showInDock {
            NSApp.applicationIconImage = NSImage(named: "DockIcon")
        }

        NotificationManager.shared.requestAuthorization()
        scheduleEvaluation(reason: "Launch")
    }

    func exportLogs() -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "JiggerMan-Logs.txt"
        panel.canCreateDirectories = true
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return nil }
        let text = LogStore.shared.exportText()
        try? text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func clearLogs() {
        LogStore.shared.clear()
    }

    private func scheduleEvaluation(reason: String) {
        evaluate(reason: reason)
        persist()
    }

    private func evaluate(reason: String) {
        let active = manualSimulateActivity
        
        jiggleManager.distance = preferences.jiggleDistance
        jiggleManager.interval = preferences.jiggleInterval
        if jiggleManager.isJiggling != active {
            jiggleManager.isJiggling = active
        }
        isActive = active
        statusText = active ? "On" : "Off"

        if lastActive != active {
            if active {
                log(action: "Jiggler Enabled", reason: reason)
                if preferences.notifyOnStartStop {
                    NotificationManager.shared.notify(title: "JiggerMan",
                                                      body: "Jiggler enabled.")
                }
            } else {
                log(action: "Jiggler Disabled", reason: reason)
                if preferences.notifyOnStartStop {
                    NotificationManager.shared.notify(title: "JiggerMan",
                                                      body: "Jiggler disabled.")
                }
            }
        }

        lastActive = active
    }

    private func log(action: String, reason: String) {
        LogStore.shared.append(LogEntry(action: action, reason: reason))
    }

    var menuBarIconName: String {
        return isActive ? "cursorarrow.motionlines" : "cursorarrow"
    }

    private func checkAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        return AXIsProcessTrustedWithOptions(options)
    }

    private func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func persist() {
        let snapshot = PersistenceStore.AppStateSnapshot(
            preferences: preferences,
            manualSimulateActivity: manualSimulateActivity
        )
        PersistenceStore.shared.save(snapshot: snapshot)
    }
}

