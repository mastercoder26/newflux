import Foundation

public struct ContentMetadata: Sendable, Equatable {
    public var kind: ContentKind
    public var displayName: String
    public var fileSize: Int64?
    public var utiIdentifier: String?
    public var details: [String: String]
    
    public init(
        kind: ContentKind,
        displayName: String,
        fileSize: Int64? = nil,
        utiIdentifier: String? = nil,
        details: [String: String] = [:]
    ) {
        self.kind = kind
        self.displayName = displayName
        self.fileSize = fileSize
        self.utiIdentifier = utiIdentifier
        self.details = details
    }
    
    public var formattedFileSize: String? {
        guard let fileSize = fileSize, fileSize >= 0 else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    public var subtitle: String {
        var parts: [String] = [kind.displayName]
        if let dimensions = details["dimensions"] {
            parts.append(dimensions)
        } else if let pages = details["pages"] {
            parts.append("\(pages) pages")
        } else if let lines = details["lines"] {
            parts.append("\(lines) lines")
        }
        if let size = formattedFileSize {
            parts.append(size)
        }
        return parts.joined(separator: " • ")
    }
}
