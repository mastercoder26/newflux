import Foundation
import AppKit

public final class ClipboardService: @unchecked Sendable {
    public static let shared = ClipboardService()
    
    private let pasteboard = NSPasteboard.general
    
    public init() {}
    
    public func copy(content: FluxContent) -> Bool {
        pasteboard.clearContents()
        switch content {
        case .text(let string):
            return pasteboard.setString(string, forType: .string)
        case .url(let url):
            if url.isFileURL {
                return pasteboard.writeObjects([url as NSURL])
            } else {
                return pasteboard.setString(url.absoluteString, forType: .string)
            }
        case .image(let image, let sourceURL):
            var written = pasteboard.writeObjects([image])
            if let fileURL = sourceURL {
                _ = pasteboard.writeObjects([fileURL as NSURL])
                written = true
            }
            return written
        case .pdf(let url), .file(let url):
            return pasteboard.writeObjects([url as NSURL])
        case .files(let urls):
            return pasteboard.writeObjects(urls as [NSURL])
        }
    }
    
    public func copy(string: String) -> Bool {
        pasteboard.clearContents()
        return pasteboard.setString(string, forType: .string)
    }
    
    public func copy(image: NSImage) -> Bool {
        pasteboard.clearContents()
        return pasteboard.writeObjects([image])
    }
    
    public func copy(fileURL: URL) -> Bool {
        pasteboard.clearContents()
        return pasteboard.writeObjects([fileURL as NSURL])
    }
    
    public func readContent() -> ContentDetectionResult? {
        ContentDetector.detectFromPasteboard(pasteboard)
    }
}
