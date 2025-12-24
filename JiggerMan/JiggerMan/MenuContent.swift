import SwiftUI

struct MenuContent: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Toggle Row
            Toggle(isOn: $appState.manualSimulateActivity) {
                Label("Simulate Activity", systemImage: "cursorarrow.motionlines")
                    .font(.body)
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
            
            Divider()
            
            // Settings Button
            if #available(macOS 14.0, *) {
                SettingsLink {
                    Label("Open Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",")
            } else {
                Button {
                    openSettings()
                } label: {
                    Label("Open Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",")
            }
            
            // Quit Button
            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit JiggerMan", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 220)
    }
    
    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else if #available(macOS 13.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}
