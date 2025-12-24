//
//  ContentView.swift
//  JiggerMan
//
//  Created by Can GULDOGAN on 23/12/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var logStore = LogStore.shared

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            logsTab
                .tabItem {
                    Label("Logs", systemImage: "list.bullet.rectangle")
                }
            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(minWidth: 500, minHeight: 350)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

private extension ContentView {
    var generalTab: some View {
        Form {
            Section("Status") {
                Text(appState.isActive ? "Jiggler: On" : "Jiggler: Off")
                    .font(.headline)
                Toggle("Simulate Activity", isOn: $appState.manualSimulateActivity)
            }

            Section("Preferences") {
                Toggle("Launch at Login", isOn: $appState.preferences.launchAtLogin)
                Toggle("Notify on Start/Stop", isOn: $appState.preferences.notifyOnStartStop)
                Toggle("Show in Dock", isOn: $appState.preferences.showInDock)
                
                VStack(alignment: .leading) {
                    Text("Jiggle Distance: \(Int(appState.preferences.jiggleDistance)) px")
                    Slider(value: $appState.preferences.jiggleDistance, in: 10...200, step: 10)
                }
            }
        }
        .padding()
    }

    var logsTab: some View {
        VStack {
            HStack {
                Button("Clear Logs") { appState.clearLogs() }
                Button("Export Logs...") { _ = appState.exportLogs() }
                Spacer()
                Picker("Retention", selection: $appState.preferences.logRetentionDays) {
                    Text("7 Days").tag(7)
                    Text("30 Days").tag(30)
                    Text("90 Days").tag(90)
                }
                .frame(width: 120)
            }
            .padding(.horizontal)

            List(logStore.entries) { entry in
                HStack {
                    Text(entry.date, style: .time)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Text(entry.action)
                        .fontWeight(.medium)
                    Spacer()
                    Text(entry.reason)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical)
    }

    var aboutTab: some View {
        VStack(spacing: 16) {
            Image("DockIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 128, height: 128)
            
            Text("JiggerMan")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .foregroundStyle(.secondary)
            
            Text("Prevents idle status by simulating activity.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Link("View on GitHub", destination: URL(string: "https://github.com/cguldogan/JiggerMan")!)
                .foregroundColor(.blue)
            
            Link(destination: URL(string: "https://www.buymeacoffee.com/cguldogan")!) {
                AsyncImage(url: URL(string: "https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=&slug=cguldogan&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Text("Buy me a coffee")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(red: 1.0, green: 0.867, blue: 0.0)) // #FFDD00
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
                .frame(height: 50)
            }
            .buttonStyle(.plain) // Remove default button styling to show the image clearly
            .padding(.top, 8)
        }
        .padding()
    }
}
