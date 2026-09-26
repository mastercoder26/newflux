import Foundation

public enum ActionError: LocalizedError, Equatable, Sendable {
    case unsupportedContent
    case invalidJSON(String)
    case invalidURL(String)
    case imageDecodeFailed
    case imageEncodeFailed(String)
    case pdfLoadFailed(String)
    case invalidPageRange(String)
    case workflowIncompatible(String)
    case actionFailed(String)
    case exportFailed(String)
    case clipboardUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedContent:
            return "The selected action does not support this content format."
        case .invalidJSON(let message):
            return "Invalid JSON: \(message)"
        case .invalidURL(let message):
            return "Invalid URL: \(message)"
        case .imageDecodeFailed:
            return "Failed to decode image data."
        case .imageEncodeFailed(let message):
            return "Failed to encode image: \(message)"
        case .pdfLoadFailed(let message):
            return "Failed to load PDF document: \(message)"
        case .invalidPageRange(let message):
            return "Invalid PDF page range: \(message)"
        case .workflowIncompatible(let message):
            return message
        case .actionFailed(let message):
            return message
        case .exportFailed(let message):
            return "Export failed: \(message)"
        case .clipboardUnavailable:
            return "Clipboard data could not be accessed."
        }
    }
}
