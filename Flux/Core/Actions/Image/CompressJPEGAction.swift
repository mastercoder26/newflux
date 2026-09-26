import Foundation
import AppKit

public struct CompressJPEGAction: FluxAction {
    public let id: ActionKind = .compressJPEG
    public let title: String = "Compress JPEG"
    public let systemImage: String = "arrow.down.right.and.arrow.up.left"
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
        
        let quality = configuration.double(for: "quality", default: 0.8)
        let (outputImage, jpegData) = try ImageUtilities.convertToJPEG(image: image, quality: quality)
        let tempURL = FileUtilities.makeTempFileURL(prefix: "image-compressed", fileExtension: "jpg")
        try jpegData.write(to: tempURL)
        
        return .image(outputImage, sourceURL: tempURL)
    }
}
