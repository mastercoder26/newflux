import SwiftUI

public struct AppCommands: Commands {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Toggle Flux Palette") {
                appState.togglePanel()
            }
            .keyboardShortcut(" ", modifiers: [.option])
            
            Button("Paste to Flux") {
                appState.showPanel()
                appState.paletteViewModel.pasteClipboard()
            }
            .keyboardShortcut("v", modifiers: [.command, .shift])
            
            Button("Reset Flux Palette") {
                appState.paletteViewModel.resetToEmpty()
            }
            .keyboardShortcut("r", modifiers: [.command])
        }
        
        CommandMenu("Palette") {
            Button("History") {
                appState.showPanel()
                appState.paletteViewModel.mode = .history
            }
            .keyboardShortcut("y", modifiers: [.command])
            
            Button("New Workflow") {
                appState.showPanel()
                appState.paletteViewModel.mode = .workflowBuilder
            }
        }
    }
}
