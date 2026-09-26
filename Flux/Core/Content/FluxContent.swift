import Foundation
import AppKit

public enum FluxContent: @unchecked Sendable {
    case text(String)
    case url(URL)
    case image(NSImage, sourceURL: URL?)
    case pdf(URL)
    case file(URL)
    case files([URL])
    
    public var textValue: String? {
        if case .text(let str) = self {
            return str
        }
        return nil
    }
    
    public var urlValue: URL? {
        if case .url(let u) = self {
            return u
        }
        return nil
    }
    
    public var imageValue: NSImage? {
        if case .image(let img, _) = self {
            return img
        }
        return nil
    }
    
    public var singleFileURL: URL? {
        switch self {
        case .url(let u) where u.isFileURL:
            return u
        case .image(_, let sourceURL):
            return sourceURL
        case .pdf(let u):
            return u
        case .file(let u):
            return u
        case .files(let urls) where urls.count == 1:
            return urls.first
        default:
            return nil
        }
    }
    
    public var allFileURLs: [URL] {
        switch self {
        case .url(let u) where u.isFileURL:
            return [u]
        case .image(_, let sourceURL):
            return sourceURL.map { [$0] } ?? []
        case .pdf(let u):
            return [u]
        case .file(let u):
            return [u]
        case .files(let urls):
            return urls
        default:
            return []
        }
    }
}
