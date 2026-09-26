import Foundation

public struct CaseAction: FluxAction {
    public let id: ActionKind = .convertCase
    public let title: String = "Change Case"
    public let systemImage: String = "textformat"
    public let acceptedKinds: Set<ContentKind> = [.text]
    
    public init() {}
    
    public func accepts(_ content: FluxContent) -> Bool {
        if case .text = content { return true }
        return false
    }
    
    public func expectedOutputKind(for inputKind: ContentKind, configuration: ActionConfiguration) -> ContentKind {
        .text
    }
    
    public func execute(_ content: FluxContent, configuration: ActionConfiguration) async throws -> FluxContent {
        guard case .text(let string) = content else {
            throw ActionError.unsupportedContent
        }
        
        let targetCase = configuration.string(for: "caseType", default: "uppercase").lowercased()
        let result: String
        switch targetCase {
        case "lowercase":
            result = string.lowercased()
        case "title", "titlecase", "title case":
            result = string.capitalized
        case "uppercase":
            fallthrough
        default:
            result = string.uppercased()
        }
        
        return .text(result)
    }
}
