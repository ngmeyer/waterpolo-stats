import SwiftUI

// MARK: - Settings Tab View
// Main settings with data management

struct SettingsTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Data")) {
                    NavigationLink(destination: DataManagementView()) {
                        Label("Data Management", systemImage: "externaldrive.fill")
                    }
                }
                
                Section(header: Text("Display")) {
                    NavigationLink(destination: DisplaySettingsView()) {
                        Label("Display Options", systemImage: "sun.max.fill")
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2025.0222")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Display Settings

struct DisplaySettingsView: View {
    @AppStorage("defaultSunlightMode") private var defaultSunlightMode = false
    @AppStorage("enableHaptics") private var enableHaptics = true
    @AppStorage("largeTextMode") private var largeTextMode = false
    
    var body: some View {
        List {
            Section(header: Text("Game Display")) {
                Toggle("Default to Sunlight Mode", isOn: $defaultSunlightMode)
                
                Toggle("Large Text Mode", isOn: $largeTextMode)
            }
            
            Section(header: Text("Feedback")) {
                Toggle("Enable Haptics", isOn: $enableHaptics)
            }
            
            Section(footer: Text("Sunlight mode uses high contrast colors for outdoor visibility. Large text mode increases font sizes throughout the app.")) {
                EmptyView()
            }
        }
        .navigationTitle("Display Options")
    }
}

// MARK: - Preview

struct SettingsTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsTabView()
    }
}
