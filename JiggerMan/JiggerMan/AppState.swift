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
            guard oldValue != manualSimulateActivity else { return }
            
            if manualSimulateActivity && !oldValue {
                if !checkAccessibilityPermissions() {
                    DispatchQueue.main.async { [weak self] in
                        self?.manualSimulateActivity = false
                        self?.openAccessibilitySettings()
                    }
                    return
                }
            }
            scheduleEvaluation(reason: "Manual")
        }
    }
    @Published var preferences: Preferences {
        didSet {
            guard oldValue != preferences else { return }
            
            if !preferences.showInDock && !preferences.showMenuBarIcon {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    guard !self.preferences.showInDock && !self.preferences.showMenuBarIcon else { return }
                    self.preferences.showMenuBarIcon = true
                }
                return
            }

            if oldValue.launchAtLogin != preferences.launchAtLogin {
                LaunchAtLoginManager.shared.setEnabled(preferences.launchAtLogin)
            }
            if oldValue.logRetentionDays != preferences.logRetentionDays {
                LogStore.shared.prune(olderThanDays: preferences.logRetentionDays)
            }
            if oldValue.showInDock != preferences.showInDock ||
               oldValue.showMenuBarIcon != preferences.showMenuBarIcon {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    NSApp.setActivationPolicy(self.preferences.showInDock ? .regular : .accessory)
                    if self.preferences.showInDock {
                        // Explicitly set the dock icon to ensure it appears
                        NSApp.applicationIconImage = NSImage(named: "DockIcon")
                        // When switching to regular, we might want to activate to show the dock icon bouncing/appearing
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
            }
            scheduleEvaluation(reason: "Preferences")
        }
    }
    @Published private(set) var isActive = false
    @Published private(set) var statusText = "Off"

    private let jiggleManager = JiggleManager()
    private var lastActive = false
    private var globalShortcutMonitor: Any?
    private var localShortcutMonitor: Any?

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
        registerGlobalShortcut()
        scheduleEvaluation(reason: "Launch")
    }

    private func registerGlobalShortcut() {
        globalShortcutMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleShortcutEvent(event)
        }

        localShortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleShortcutEvent(event) == true {
                return nil
            }
            return event
        }
    }

    @discardableResult
    private func handleShortcutEvent(_ event: NSEvent) -> Bool {
        let requiredFlags: NSEvent.ModifierFlags = [.control, .option]
        let pressedFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard pressedFlags.contains(requiredFlags),
              event.charactersIgnoringModifiers?.lowercased() == "j" else {
            return false
        }

        DispatchQueue.main.async { [weak self] in
            self?.manualSimulateActivity.toggle()
        }
        return true
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
        // Defer the entire evaluation to avoid "Publishing changes from within view updates"
        // when triggered by a view binding (like a Toggle)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.evaluate(reason: reason)
            self.persist()
        }
    }

    private func evaluate(reason: String) {
        let active = manualSimulateActivity
        
        jiggleManager.distance = preferences.jiggleDistance
        jiggleManager.interval = preferences.jiggleInterval
        if jiggleManager.isJiggling != active {
            jiggleManager.isJiggling = active
        }
        
        if self.isActive != active {
            self.isActive = active
        }
        let newStatusText = active ? "On" : "Off"
        if self.statusText != newStatusText {
            self.statusText = newStatusText
        }

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
        let snapshot = AppStateSnapshot(
            preferences: preferences,
            manualSimulateActivity: manualSimulateActivity
        )
        PersistenceStore.shared.save(snapshot: snapshot)
    }
}

