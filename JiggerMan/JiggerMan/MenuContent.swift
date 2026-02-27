import SwiftUI

struct MenuContent: View {
    @ObservedObject var appState: AppState
    @State private var isHoveringToggle = false
    
    var body: some View {
        let toggleBinding = Binding<Bool>(
            get: { appState.manualSimulateActivity },
            set: { newValue in
                if appState.manualSimulateActivity != newValue {
                    DispatchQueue.main.async {
                        appState.manualSimulateActivity = newValue
                    }
                }
            }
        )

        VStack(alignment: .leading, spacing: 4) {
            // Toggle Row
            Toggle(isOn: toggleBinding) {
                Label("Simulate Activity", systemImage: "cursorarrow.motionlines")
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(isHoveringToggle ? Color.accentColor : Color.clear)
            .foregroundStyle(isHoveringToggle ? .white : .primary)
            .cornerRadius(4)
            .onHover { isHoveringToggle = $0 }
            
            Divider()
                .padding(.vertical, 4)
            
            // Settings Button
            if #available(macOS 14.0, *) {
                SettingsLink {
                    Label("Open Settings", systemImage: "gear")
                }
                .buttonStyle(MenuButtonStyle())
                .keyboardShortcut(",")
                .simultaneousGesture(TapGesture().onEnded {
                    NSApp.activate(ignoringOtherApps: true)
                })
            } else {
                Button {
                    openSettings()
                } label: {
                    Label("Open Settings", systemImage: "gear")
                }
                .buttonStyle(MenuButtonStyle())
                .keyboardShortcut(",")
            }
            
            // Quit Button
            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit JiggerMan", systemImage: "power")
            }
            .buttonStyle(MenuButtonStyle())
            .keyboardShortcut("q")
        }
        .padding(8)
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

struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HoverButton(configuration: configuration)
    }
    
    struct HoverButton: View {
        let configuration: Configuration
        @State private var isHovering = false
        
        var body: some View {
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(isHovering ? Color.accentColor : Color.clear)
                .foregroundStyle(isHovering ? .white : .primary)
                .cornerRadius(4)
                .onHover { isHovering = $0 }
        }
    }
}
