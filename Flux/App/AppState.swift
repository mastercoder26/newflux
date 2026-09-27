import Foundation
import SwiftUI
import AppKit

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    public let paletteViewModel: PaletteViewModel
    
    private init() {
        self.paletteViewModel = PaletteViewModel()
    }
    
    public func initialize() {
        // Initialize panel with PaletteView
        let view = PaletteView(viewModel: paletteViewModel)
        FluxPanelController.shared.setup(rootView: view)
        
        // Register global shortcut
        HotkeyService.shared.register { [weak self] in
            self?.togglePanel()
        }
    }
    
    public func togglePanel() {
        FluxPanelController.shared.toggle()
    }
    
    public func showPanel() {
        FluxPanelController.shared.show()
    }
    
    public func hidePanel() {
        FluxPanelController.shared.hide()
    }
}
