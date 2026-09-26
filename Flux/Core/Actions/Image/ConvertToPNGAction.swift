import Foundation
import AppKit

public struct ConvertToPNGAction: FluxAction {
    public let id: ActionKind = .convertToPNG
    public let title: String = "Convert to PNG"
    public let systemImage: String = "photo"
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
        .image
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
        
        let (outputImage, pngData) = try ImageUtilities.convertToPNG(image: image)
        let tempURL = FileUtilities.makeTempFileURL(prefix: "image-converted", fileExtension: "png")
        try pngData.write(to: tempURL)
        
        return .image(outputImage, sourceURL: tempURL)
    }
}
