import Foundation

public struct RemoveBlankLinesAction: FluxAction {
    public let id: ActionKind = .removeBlankLines
    public let title: String = "Remove Blank Lines"
    public let systemImage: String = "arrow.up.and.down.text.horizontal"
    public let acceptedKinds: Set<ContentKind> = [.text, .json]
    
    public init() {}
    
    public func accepts(_ content: FluxContent) -> Bool {
        if case .text = content { return true }
        return false
    }
    
    public func expectedOutputKind(for inputKind: ContentKind, configuration: ActionConfiguration) -> ContentKind {
        inputKind
    }
    
    public func execute(_ content: FluxContent, configuration: ActionConfiguration) async throws -> FluxContent {
        guard case .text(let string) = content else {
            throw ActionError.unsupportedContent
        }
        
        let cleaned = clean(string)
        return .text(cleaned)
    }
    
    public func clean(_ string: String) -> String {
        let normalized = string
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        // Collapse 3 or more consecutive newlines (lines that may contain whitespace)
        // Regex: \n([ \t]*\n){2,} -> replace with \n\n
        let pattern = "\\n([ \\t]*\\n){2,}"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: (normalized as NSString).length)
        let result = regex?.stringByReplacingMatches(in: normalized, options: [], range: range, withTemplate: "\n\n") ?? normalized
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
