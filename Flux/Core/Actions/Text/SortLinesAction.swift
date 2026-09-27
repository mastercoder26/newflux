import Foundation

public struct SortLinesAction: FluxAction {
    public let id: ActionKind = .sortLines
    public let title: String = "Sort Lines"
    public let systemImage: String = "text.line.first.and.arrowtriangle.forward"
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

        let descending = configuration.string(for: "order", default: "ascending").lowercased() == "descending"
        let trimmed = configuration.string(for: "trim", default: "false").lowercased() == "true"

        var lines = string.components(separatedBy: "\n")
        if trimmed {
            lines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
        }
        lines.sort()
        if descending {
            lines.reverse()
        }

        return .text(lines.joined(separator: "\n"))
    }
}
