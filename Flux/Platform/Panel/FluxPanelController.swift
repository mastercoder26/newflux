import Foundation
import AppKit
import SwiftUI

public final class FluxPanel: NSPanel {
    public override var canBecomeKey: Bool {
        true
    }
    
    public override var canBecomeMain: Bool {
        true
    }
    
    public override func cancelOperation(_ sender: Any?) {
        orderOut(sender)
    }
}

@MainActor
public final class FluxPanelController: NSObject, NSWindowDelegate {
    public static let shared = FluxPanelController()
    
    private var panel: FluxPanel?
    private var hostingController: NSHostingController<AnyView>?
    
    public override init() {
        super.init()
    }
    
    public func setup<Content: View>(rootView: Content) {
        if self.panel != nil {
            self.hostingController?.rootView = AnyView(rootView)
            return
        }
        
        let hosting = NSHostingController(rootView: AnyView(rootView))
        self.hostingController = hosting
        
        let p = FluxPanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 530),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        p.isFloatingPanel = true
        p.level = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.titleVisibility = .hidden
        p.titlebarAppearsTransparent = true
        p.isMovableByWindowBackground = true
        p.isReleasedWhenClosed = false
        p.hidesOnDeactivate = false
        p.delegate = self
        
        // Native frosted glass look
        p.isOpaque = false
        p.backgroundColor = .clear
        
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.masksToBounds = true
        
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.addSubview(hosting.view)
        
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor)
        ])
        
        p.contentView = visualEffect
        self.panel = p
    }
    
    public func toggle() {
        guard let panel = panel else { return }
        if panel.isVisible && panel.isKeyWindow {
            panel.orderOut(nil)
        } else {
            show()
        }
    }
    
    public func show() {
        guard let panel = panel else { return }
        
        if !panel.isVisible {
            centerOnActiveScreen(panel)
        }
        
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func hide() {
        panel?.orderOut(nil)
    }
    
    public var window: NSWindow? {
        panel
    }
    
    private func centerOnActiveScreen(_ window: NSWindow) {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let screen = screen else {
            window.center()
            return
        }
        
        let screenRect = screen.visibleFrame
        let windowRect = window.frame
        let newX = screenRect.midX - (windowRect.width / 2.0)
        let newY = screenRect.midY - (windowRect.height / 2.0) + 40 // slightly above optical center
        window.setFrameOrigin(NSPoint(x: newX, y: newY))
    }
}
