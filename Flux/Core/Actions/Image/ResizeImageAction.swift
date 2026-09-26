import Foundation
import AppKit

public struct ResizeImageAction: FluxAction {
    public let id: ActionKind = .resizeImage
    public let title: String = "Resize Image"
    public let systemImage: String = "aspectratio"
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
        
        let targetWidth = configuration.int(for: "width", default: 1200)
        let targetHeight = configuration.int(for: "height", default: 0)
        let preserveAspect = configuration.bool(for: "preserveAspectRatio", default: true)
        
        let resized = try ImageUtilities.resize(
            image: image,
            targetWidth: targetWidth > 0 ? targetWidth : 1200,
            targetHeight: targetHeight > 0 ? targetHeight : nil,
            preserveAspectRatio: preserveAspect
        )
        
        let (_, pngData) = try ImageUtilities.convertToPNG(image: resized)
        let tempURL = FileUtilities.makeTempFileURL(prefix: "image-resized", fileExtension: "png")
        try pngData.write(to: tempURL)
        
        return .image(resized, sourceURL: tempURL)
    }
}
