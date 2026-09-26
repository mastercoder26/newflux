import Foundation

public struct MinifyJSONAction: FluxAction {
    public let id: ActionKind = .minifyJSON
    public let title: String = "Minify JSON"
    public let systemImage: String = "arrow.right.arrow.left"
    public let acceptedKinds: Set<ContentKind> = [.json, .text]
    
    public init() {}
    
    public func accepts(_ content: FluxContent) -> Bool {
        guard case .text(let text) = content else { return false }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data, options: [])) != nil
    }
    
    public func expectedOutputKind(for inputKind: ContentKind, configuration: ActionConfiguration) -> ContentKind {
        .json
    }
    
    public func execute(_ content: FluxContent, configuration: ActionConfiguration) async throws -> FluxContent {
        guard case .text(let text) = content else {
            throw ActionError.unsupportedContent
        }
        
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else {
            throw ActionError.invalidJSON("Unable to read string data.")
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let minifiedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            guard let minifiedString = String(data: minifiedData, encoding: .utf8) else {
                throw ActionError.invalidJSON("Failed to encode minified JSON string.")
            }
            return .text(minifiedString)
        } catch {
            throw ActionError.invalidJSON(error.localizedDescription)
        }
    }
}
