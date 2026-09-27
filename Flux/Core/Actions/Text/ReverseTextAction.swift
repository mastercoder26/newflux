import Foundation

public struct ReverseTextAction: FluxAction {
    public let id: ActionKind = .reverseText
    public let title: String = "Reverse Text"
    public let systemImage: String = "arrow.left.arrow.right"
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

        let byLine = configuration.string(for: "byLine", default: "false").lowercased() == "true"
        let result: String
        if byLine {
            result = string
                .components(separatedBy: "\n")
                .map { String($0.reversed()) }
                .joined(separator: "\n")
        } else {
            result = String(string.reversed())
        }

        return .text(result)
    }
}
