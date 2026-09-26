import Foundation
import AppKit

public struct OCRAction: FluxAction {
    public let id: ActionKind = .ocr
    public let title: String = "Extract Text (OCR)"
    public let systemImage: String = "text.viewfinder"
    public let acceptedKinds: Set<ContentKind> = [.image]
    
    public init() {}
    
    public func accepts(_ content: FluxContent) -> Bool {
        switch content {
        case .image:
            return true
        case .file(let url):
            let ext = url.pathExtension.lowercased()
            return ["png", "jpg", "jpeg", "webp", "tiff", "gif", "bmp"].contains(ext)
        default:
            return false
        }
    }
    
    public func expectedOutputKind(for inputKind: ContentKind, configuration: ActionConfiguration) -> ContentKind {
        .text
    }
    
    public func execute(_ content: FluxContent, configuration: ActionConfiguration) async throws -> FluxContent {
        let image: NSImage
        switch content {
        case .image(let img, _):
            image = img
        case .file(let url):
            guard let loaded = NSImage(contentsOf: url) else {
                throw ActionError.imageDecodeFailed
            }
            image = loaded
        default:
            throw ActionError.unsupportedContent
        }
        
        let recognizedText = try await ImageUtilities.performOCR(on: image)
        return .text(recognizedText)
    }
}
