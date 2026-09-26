import Foundation

public enum ContentKind: String, Codable, CaseIterable, Sendable {
    case text
    case json
    case url
    case image
    case pdf
    case file
    case multipleFiles
    case multiplePDFs
    
    public var displayName: String {
        switch self {
        case .text:
            return "Text"
        case .json:
            return "JSON"
        case .url:
            return "URL"
        case .image:
            return "Image"
        case .pdf:
            return "PDF"
        case .file:
            return "File"
        case .multipleFiles:
            return "Multiple Files"
        case .multiplePDFs:
            return "Multiple PDFs"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .text:
            return "text.alignleft"
        case .json:
            return "curlybraces"
        case .url:
            return "link"
        case .image:
            return "photo"
        case .pdf:
            return "doc.richtext"
        case .file:
            return "doc"
        case .multipleFiles:
            return "doc.on.doc"
        case .multiplePDFs:
            return "doc.richtext.fill"
        }
    }
}
