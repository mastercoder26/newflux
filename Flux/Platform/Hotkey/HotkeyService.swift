import Foundation
import AppKit
import KeyboardShortcuts

public extension KeyboardShortcuts.Name {
    static let toggleFluxPanel = Self("toggleFluxPanel", default: .init(.space, modifiers: [.option]))
}

@MainActor
public final class HotkeyService {
    public static let shared = HotkeyService()
    
    private var isListening = false
    
    private init() {}
    
    public func register(onToggle: @escaping () -> Void) {
        guard !isListening else { return }
        isListening = true
        
        KeyboardShortcuts.onKeyUp(for: .toggleFluxPanel) {
            onToggle()
        }
    }
}
