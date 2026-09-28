import Foundation

public struct CountLinesAction: FluxAction {
    public let id: ActionKind = .countLines
    public let title: String = "Count Lines"
    public let systemImage: String = "text.line.3"
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

        let lines = string.components(separatedBy: "\n").count
        let words = string.split(whereSeparator: { $0.isWhitespace }).count
        let characters = string.count
        let summary = "lines: \(lines)\nwords: \(words)\ncharacters: \(characters)"
        return .text(summary)
    }
}
