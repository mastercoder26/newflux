import Foundation

public struct SlugifyAction: FluxAction {
    public let id: ActionKind = .slugify
    public let title: String = "Slugify"
    public let systemImage: String = "number"
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

        let separator = configuration.string(for: "separator", default: "-")
        let sep = separator.isEmpty ? "-" : separator

        let lowered = string.lowercased()
        let scalars = lowered.unicodeScalars.map { scalar -> String in
            if scalar.value >= 0x61 && scalar.value <= 0x7A { // a-z
                return String(scalar)
            }
            if scalar.value >= 0x30 && scalar.value <= 0x39 { // 0-9
                return String(scalar)
            }
            return " "
        }.joined(separator: "")

        let words = scalars.split(whereSeparator: { $0 == " " }).map(String.init)
        return .text(words.joined(separator: sep))
    }
}
