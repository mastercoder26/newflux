import Foundation

public struct Base64Action: FluxAction {
    public let id: ActionKind = .base64Encode
    public let title: String = "Base64 Encode / Decode"
    public let systemImage: String = "squaregrid.2x2"
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

        let mode = configuration.string(for: "mode", default: "encode").lowercased()
        let result: String
        switch mode {
        case "decode":
            let cleaned = string.unicodeScalars.filter {
                $0 != "\n" && $0 != "\r" && $0 != " " && $0 != "\t"
            }.map { Character($0) }
            let compact = String(cleaned)
            guard let decoded = Data(base64Encoded: compact) else {
                throw ActionError.actionFailed("input is not valid base64")
            }
            result = String(data: decoded, encoding: .utf8) ?? ""
        case "encode":
            fallthrough
        default:
            result = Data(string.utf8).base64EncodedString()
        }

        return .text(result)
    }
}
