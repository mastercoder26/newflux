import Foundation
import AppKit

public struct GenerateQRCodeAction: FluxAction {
    public let id: ActionKind = .generateQRCode
    public let title: String = "Generate QR Code"
    public let systemImage: String = "qrcode"
    public let acceptedKinds: Set<ContentKind> = [.url, .text]
    
    public init() {}
    
    public func accepts(_ content: FluxContent) -> Bool {
        switch content {
        case .url, .text:
            return true
        default:
            return false
        }
    }
    
    public func expectedOutputKind(for inputKind: ContentKind, configuration: ActionConfiguration) -> ContentKind {
        .image
    }
    
    public func execute(_ content: FluxContent, configuration: ActionConfiguration) async throws -> FluxContent {
        let string: String
        switch content {
        case .url(let u):
            string = u.absoluteString
        case .text(let str):
            string = str
        default:
            throw ActionError.unsupportedContent
        }
        
        let (qrImage, pngData) = try ImageUtilities.generateQRCode(from: string, targetSize: 512)
        let tempURL = FileUtilities.makeTempFileURL(prefix: "qr", fileExtension: "png")
        try pngData.write(to: tempURL)
        
        return .image(qrImage, sourceURL: tempURL)
    }
}
