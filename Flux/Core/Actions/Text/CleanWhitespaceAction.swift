import Foundation

public struct CleanWhitespaceAction: FluxAction {
    public let id: ActionKind = .cleanWhitespace
    public let title: String = "Clean Whitespace"
    public let systemImage: String = "wand.and.stars"
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
        // Normalize CRLF and CR to LF
        let normalized = string
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        let lines = normalized.components(separatedBy: "\n")
        let cleanedLines = lines.map { line -> String in
            var cleaned = line.replacingOccurrences(of: "\t", with: " ")
            while cleaned.contains("  ") {
                cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
            }
            return cleaned.trimmingCharacters(in: .whitespaces)
        }
        
        let result = cleanedLines.joined(separator: "\n")
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
