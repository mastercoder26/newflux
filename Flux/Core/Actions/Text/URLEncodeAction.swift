import Foundation

public struct URLEncodeAction: FluxAction {
    public let id: ActionKind = .urlEncode
    public let title: String = "URL Encode / Decode"
    public let systemImage: String = "link.circle"
    public let acceptedKinds: Set<ContentKind> = [.text, .url]

    public init() {}

    public func accepts(_ content: FluxContent) -> Bool {
        if case .text = content { return true }
        if case .url = content { return true }
        return false
    }

    public func expectedOutputKind(for inputKind: ContentKind, configuration: ActionConfiguration) -> ContentKind {
        .text
    }

    public func execute(_ content: FluxContent, configuration: ActionConfiguration) async throws -> FluxContent {
        let input: String
        switch content {
        case .text(let string): input = string
        case .url(let url): input = url.absoluteString
        default: throw ActionError.unsupportedContent
        }

        // Empty input encodes to itself; skip the codec so we don't surface
        // a confusing percent-encoded empty string to the user.
        if input.isEmpty { return .text("") }

        let mode = configuration.string(for: "mode", default: "encode").lowercased()
        let result: String
        switch mode {
        case "decode":
            guard let decoded = input.removingPercentEncoding else {
                throw ActionError.invalidURL("input is not valid percent-encoded text")
            }
            result = decoded
        case "encode":
            fallthrough
        default:
            result = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
        }

        return .text(result)
    }
}
