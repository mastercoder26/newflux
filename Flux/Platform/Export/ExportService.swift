import Foundation
import AppKit
import UniformTypeIdentifiers

@MainActor
public final class ExportService {
    public static let shared = ExportService()
    
    private init() {}
    
    public func export(content: FluxContent, suggestedName: String? = nil, from window: NSWindow? = nil) async throws -> URL {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        
        switch content {
        case .text(let string):
            savePanel.nameFieldStringValue = suggestedName ?? "transformed.txt"
            savePanel.allowedContentTypes = [.plainText, .json]
            
            let response = await show(panel: savePanel, from: window)
            guard response == .OK, let destination = savePanel.url else {
                throw ActionError.exportFailed("Export was cancelled.")
            }
            try string.write(to: destination, atomically: true, encoding: .utf8)
            return destination
            
        case .url(let url):
            if url.isFileURL {
                savePanel.nameFieldStringValue = suggestedName ?? url.lastPathComponent
                if let ut = UTType(filenameExtension: url.pathExtension) {
                    savePanel.allowedContentTypes = [ut]
                }
                let response = await show(panel: savePanel, from: window)
                guard response == .OK, let destination = savePanel.url else {
                    throw ActionError.exportFailed("Export was cancelled.")
                }
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: url, to: destination)
                return destination
            } else {
                savePanel.nameFieldStringValue = suggestedName ?? "link.txt"
                savePanel.allowedContentTypes = [.plainText]
                let response = await show(panel: savePanel, from: window)
                guard response == .OK, let destination = savePanel.url else {
                    throw ActionError.exportFailed("Export was cancelled.")
                }
                try url.absoluteString.write(to: destination, atomically: true, encoding: .utf8)
                return destination
            }
            
        case .image(let image, let sourceURL):
            let defaultName = suggestedName ?? (sourceURL?.lastPathComponent ?? "image.png")
            savePanel.nameFieldStringValue = defaultName
            savePanel.allowedContentTypes = [.png, .jpeg]
            
            let response = await show(panel: savePanel, from: window)
            guard response == .OK, let destination = savePanel.url else {
                throw ActionError.exportFailed("Export was cancelled.")
            }
            
            if destination.pathExtension.lowercased() == "jpg" || destination.pathExtension.lowercased() == "jpeg" {
                let (_, data) = try ImageUtilities.convertToJPEG(image: image, quality: 0.85)
                try data.write(to: destination)
            } else {
                let (_, data) = try ImageUtilities.convertToPNG(image: image)
                try data.write(to: destination)
            }
            return destination
            
        case .pdf(let url):
            savePanel.nameFieldStringValue = suggestedName ?? url.lastPathComponent
            savePanel.allowedContentTypes = [.pdf]
            
            let response = await show(panel: savePanel, from: window)
            guard response == .OK, let destination = savePanel.url else {
                throw ActionError.exportFailed("Export was cancelled.")
            }
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: url, to: destination)
            return destination
            
        case .file(let url):
            savePanel.nameFieldStringValue = suggestedName ?? url.lastPathComponent
            if let ut = UTType(filenameExtension: url.pathExtension) {
                savePanel.allowedContentTypes = [ut]
            }
            
            let response = await show(panel: savePanel, from: window)
            guard response == .OK, let destination = savePanel.url else {
                throw ActionError.exportFailed("Export was cancelled.")
            }
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: url, to: destination)
            return destination
            
        case .files(let urls):
            guard let first = urls.first else {
                throw ActionError.actionFailed("No files to export.")
            }
            return try await export(content: .file(first), suggestedName: suggestedName, from: window)
        }
    }
    
    public func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    private func show(panel: NSSavePanel, from window: NSWindow?) async -> NSApplication.ModalResponse {
        if let window = window {
            return await panel.beginSheetModal(for: window)
        } else {
            return panel.runModal()
        }
    }
}
