import Foundation

public struct CleanURLAction: FluxAction {
    public let id: ActionKind = .cleanURL
    public let title: String = "Clean URL"
    public let systemImage: String = "link.badge.plus"
    public let acceptedKinds: Set<ContentKind> = [.url]
    
    public init() {}
    
    public func accepts(_ content: FluxContent) -> Bool {
        switch content {
        case .url:
            return true
        case .text(let str):
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            if let u = URL(string: trimmed), let scheme = u.scheme?.lowercased(), ["http", "https"].contains(scheme), u.host != nil {
                return true
            }
            return false
        default:
            return false
        }
    }
    
    public func expectedOutputKind(for inputKind: ContentKind, configuration: ActionConfiguration) -> ContentKind {
        .url
    }
    
    public func execute(_ content: FluxContent, configuration: ActionConfiguration) async throws -> FluxContent {
        let url: URL
        switch content {
        case .url(let u):
            url = u
        case .text(let str):
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let u = URL(string: trimmed), let scheme = u.scheme?.lowercased(), ["http", "https"].contains(scheme), u.host != nil else {
                throw ActionError.invalidURL("Input is not a valid HTTP/HTTPS URL.")
            }
            url = u
        default:
            throw ActionError.unsupportedContent
        }
        
        let cleaned = URLUtilities.removeTrackingParameters(from: url)
        return .url(cleaned)
    }
}
