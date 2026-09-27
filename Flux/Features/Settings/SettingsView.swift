import SwiftUI
import KeyboardShortcuts

public struct SettingsView: View {
    @AppStorage("showRecentWorkflows") private var showRecentWorkflows = true
    @AppStorage("defaultJPEGQuality") private var defaultJPEGQuality = 0.85
    @AppStorage("defaultResizeWidth") private var defaultResizeWidth = 1200
    
    @State private var historyClearedAlert = false
    
    public init() {}
    
    public var body: some View {
        Form {
            Section("General") {
                HStack {
                    Text("Global Shortcut:")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .toggleFluxPanel)
                }
                
                Toggle("Show recent workflows on empty panel", isOn: $showRecentWorkflows)
                
                HStack {
                    Text("History:")
                    Spacer()
                    Button("Clear History") {
                        HistoryStore.shared.clear()
                        historyClearedAlert = true
                    }
                }
            }
            
            Section("Processing Defaults") {
                HStack {
                    Text("Default Resize Width:")
                    Spacer()
                    TextField("Width", value: $defaultResizeWidth, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                    Text("px")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Default JPEG Quality:")
                    Spacer()
                    Slider(value: $defaultJPEGQuality, in: 0.1...1.0, step: 0.05)
                        .frame(width: 140)
                    Text("\(Int(defaultJPEGQuality * 100))%")
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 45, alignment: .trailing)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 320)
        .alert("History Cleared", isPresented: $historyClearedAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}
