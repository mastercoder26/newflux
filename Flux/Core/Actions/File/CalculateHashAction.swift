import Foundation

public struct CalculateHashAction: FluxAction {
    public let id: ActionKind = .calculateHash
    public let title: String = "Calculate SHA-256"
    public let systemImage: String = "number"
    public let acceptedKinds: Set<ContentKind> = [.file, .image, .pdf, .text, .json]
    
    public init() {}
    
    public func accepts(_ content: FluxContent) -> Bool {
        switch content {
        case .file, .pdf, .image, .text:
            return true
        case .files(let urls):
            return urls.count == 1
        default:
            return false
        }
    }
    
    public func expectedOutputKind(for inputKind: ContentKind, configuration: ActionConfiguration) -> ContentKind {
        .text
    }
    
    public func execute(_ content: FluxContent, configuration: ActionConfiguration) async throws -> FluxContent {
        if let fileURL = content.singleFileURL {
            let hash = try FileUtilities.calculateSHA256(for: fileURL)
            return .text(hash)
        }
        
        switch content {
        case .text(let str):
            guard let data = str.data(using: .utf8) else {
                throw ActionError.actionFailed("Failed to encode text data for hashing.")
            }
            let hash = FileUtilities.calculateSHA256(for: data)
            return .text(hash)
        case .image(let image, _):
            let (_, pngData) = try ImageUtilities.convertToPNG(image: image)
            let hash = FileUtilities.calculateSHA256(for: pngData)
            return .text(hash)
        default:
            throw ActionError.unsupportedContent
        }
    }
}
