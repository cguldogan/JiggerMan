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
                    }
                    return
                }
            }
            updateMouseMovementMonitor()
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
            if oldValue.showInDock != preferences.showInDock ||
               oldValue.showMenuBarIcon != preferences.showMenuBarIcon {
                ensureAtLeastOneVisibleEntry()
                NSApp.setActivationPolicy(preferences.showInDock ? .regular : .accessory)
                if preferences.showInDock {
                    NSApp.applicationIconImage = NSImage(named: "DockIcon")
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            if oldValue.stopOnMouseMovement != preferences.stopOnMouseMovement {
                updateMouseMovementMonitor()
            }
            scheduleEvaluation(reason: "Preferences")
            persist()
        }
    }
    @Published private(set) var isActive = false
    @Published private(set) var statusText = "Off"

    private let jiggleManager = JiggleManager()
    private var lastActive = false
    private var globalShortcutMonitor: Any?
    private var localShortcutMonitor: Any?
    private var mouseMovementMonitor: Any?

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

        LogStore.shared.prune(olderThanDays: preferences.logRetentionDays)

        // Apply initial dock state
        NSApp.setActivationPolicy(preferences.showInDock ? .regular : .accessory)
        if preferences.showInDock {
            NSApp.applicationIconImage = NSImage(named: "DockIcon")
        }

        NotificationManager.shared.requestAuthorization()
        registerGlobalShortcut()
        updateMouseMovementMonitor()
        scheduleEvaluation(reason: "Launch")
    }

    // MARK: - Global Keyboard Shortcut (Ctrl+Option+J)

    private func registerGlobalShortcut() {
        // Monitor when app is NOT focused
        globalShortcutMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleShortcutEvent(event)
        }
        // Monitor when app IS focused
        localShortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleShortcutEvent(event) == true {
                return nil // consume the event
            }
            return event
        }
    }

    @discardableResult
    private func handleShortcutEvent(_ event: NSEvent) -> Bool {
        // Ctrl+Option+J
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

    // MARK: - Mouse Movement Monitor

    private func updateMouseMovementMonitor() {
        // Remove existing monitor
        if let monitor = mouseMovementMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMovementMonitor = nil
        }

        // Only install monitor when simulation is active and preference is enabled
        guard preferences.stopOnMouseMovement, manualSimulateActivity else { return }

        mouseMovementMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            guard let self = self else { return }
            // Ignore movements caused by our own jiggle
            guard !self.jiggleManager.isPerformingJiggle else { return }
            DispatchQueue.main.async {
                guard self.manualSimulateActivity else { return }
                self.manualSimulateActivity = false
                self.log(action: "Jiggler Disabled", reason: "User mouse movement detected")
            }
        }
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
        jiggleManager.isJiggling = active
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

    /// Ensures at least one of Dock icon or menu bar icon is visible.
    private func ensureAtLeastOneVisibleEntry() {
        if !preferences.showInDock && !preferences.showMenuBarIcon {
            preferences.showMenuBarIcon = true
        }
    }

    private func persist() {
        let snapshot = PersistenceStore.AppStateSnapshot(
            preferences: preferences,
            manualSimulateActivity: manualSimulateActivity
        )
        PersistenceStore.shared.save(snapshot: snapshot)
    }
}

