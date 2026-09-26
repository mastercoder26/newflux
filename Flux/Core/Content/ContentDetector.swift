import Foundation
import AppKit
import UniformTypeIdentifiers
import PDFKit

public struct ContentDetectionResult: Sendable {
    public let content: FluxContent
    public let metadata: ContentMetadata
    
    public init(content: FluxContent, metadata: ContentMetadata) {
        self.content = content
        self.metadata = metadata
    }
}

public struct ContentDetector: Sendable {
    public init() {}
    
    public static func detectFromPasteboard(_ pasteboard: NSPasteboard = .general) -> ContentDetectionResult? {
        let detector = ContentDetector()
        
        // 1. File URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL], !urls.isEmpty {
            return detector.detect(urls: urls)
        }
        
        // 2. Images
        if let image = NSImage(pasteboard: pasteboard) {
            let metadata = ContentMetadata(
                kind: .image,
                displayName: "Pasted Image",
                fileSize: nil,
                utiIdentifier: UTType.image.identifier,
                details: [
                    "dimensions": "\(Int(image.size.width)) × \(Int(image.size.height))"
                ]
            )
            return ContentDetectionResult(content: .image(image, sourceURL: nil), metadata: metadata)
        }
        
        // 3. URLs from pasteboard objects
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let firstURL = urls.first,
           let scheme = firstURL.scheme?.lowercased(),
           ["http", "https"].contains(scheme),
           firstURL.host != nil {
            return detector.detect(url: firstURL)
        }
        
        // 4. Plain text
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            return detector.detect(text: string)
        }
        
        return nil
    }
    
    public func detect(text: String) -> ContentDetectionResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for valid HTTP/HTTPS URL
        if let detectorURL = parseHTTPURL(from: trimmed) {
            let metadata = ContentMetadata(
                kind: .url,
                displayName: detectorURL.host ?? detectorURL.absoluteString,
                utiIdentifier: UTType.url.identifier,
                details: [
                    "scheme": detectorURL.scheme ?? "",
                    "host": detectorURL.host ?? ""
                ]
            )
            return ContentDetectionResult(content: .url(detectorURL), metadata: metadata)
        }
        
        // Check for valid JSON
        if isValidJSON(trimmed) {
            let lineCount = text.components(separatedBy: .newlines).count
            let byteCount = Int64(text.utf8.count)
            let metadata = ContentMetadata(
                kind: .json,
                displayName: "JSON Payload",
                fileSize: byteCount,
                utiIdentifier: UTType.json.identifier,
                details: [
                    "lines": "\(lineCount)",
                    "characters": "\(text.count)"
                ]
            )
            return ContentDetectionResult(content: .text(text), metadata: metadata)
        }
        
        // Plain text
        let lineCount = text.components(separatedBy: .newlines).count
        let byteCount = Int64(text.utf8.count)
        let preview = trimmed.components(separatedBy: .newlines).first ?? "Text"
        let displayName = preview.count > 30 ? String(preview.prefix(27)) + "..." : preview
        let metadata = ContentMetadata(
            kind: .text,
            displayName: displayName.isEmpty ? "Plain Text" : displayName,
            fileSize: byteCount,
            utiIdentifier: UTType.plainText.identifier,
            details: [
                "lines": "\(lineCount)",
                "characters": "\(text.count)"
            ]
        )
        return ContentDetectionResult(content: .text(text), metadata: metadata)
    }
    
    public func detect(url: URL) -> ContentDetectionResult {
        if url.isFileURL {
            return detect(fileURL: url)
        }
        
        let metadata = ContentMetadata(
            kind: .url,
            displayName: url.host ?? url.absoluteString,
            utiIdentifier: UTType.url.identifier,
            details: [
                "scheme": url.scheme ?? "",
                "host": url.host ?? ""
            ]
        )
        return ContentDetectionResult(content: .url(url), metadata: metadata)
    }
    
    public func detect(fileURL: URL) -> ContentDetectionResult {
        let utType = utType(for: fileURL)
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? NSNumber)?.int64Value
        let fileName = fileURL.lastPathComponent
        
        if utType.conforms(to: .pdf) {
            var pageCount: Int? = nil
            if let pdfDoc = PDFDocument(url: fileURL) {
                pageCount = pdfDoc.pageCount
            }
            var details: [String: String] = [:]
            if let pageCount = pageCount {
                details["pages"] = "\(pageCount)"
            }
            let metadata = ContentMetadata(
                kind: .pdf,
                displayName: fileName,
                fileSize: fileSize,
                utiIdentifier: utType.identifier,
                details: details
            )
            return ContentDetectionResult(content: .pdf(fileURL), metadata: metadata)
        }
        
        if utType.conforms(to: .image) {
            var details: [String: String] = [:]
            if let image = NSImage(contentsOf: fileURL) {
                details["dimensions"] = "\(Int(image.size.width)) × \(Int(image.size.height))"
                let metadata = ContentMetadata(
                    kind: .image,
                    displayName: fileName,
                    fileSize: fileSize,
                    utiIdentifier: utType.identifier,
                    details: details
                )
                return ContentDetectionResult(content: .image(image, sourceURL: fileURL), metadata: metadata)
            }
        }
        
        let metadata = ContentMetadata(
            kind: .file,
            displayName: fileName,
            fileSize: fileSize,
            utiIdentifier: utType.identifier
        )
        return ContentDetectionResult(content: .file(fileURL), metadata: metadata)
    }
    
    public func detect(urls: [URL]) -> ContentDetectionResult {
        guard !urls.isEmpty else {
            return detect(text: "")
        }
        
        if urls.count == 1 {
            return detect(fileURL: urls[0])
        }
        
        let allArePDFs = urls.allSatisfy { url in
            utType(for: url).conforms(to: .pdf)
        }
        
        var totalSize: Int64 = 0
        for u in urls {
            if let sz = (try? FileManager.default.attributesOfItem(atPath: u.path)[.size] as? NSNumber)?.int64Value {
                totalSize += sz
            }
        }
        
        if allArePDFs {
            let metadata = ContentMetadata(
                kind: .multiplePDFs,
                displayName: "\(urls.count) PDF files",
                fileSize: totalSize,
                utiIdentifier: UTType.pdf.identifier,
                details: ["count": "\(urls.count)"]
            )
            return ContentDetectionResult(content: .files(urls), metadata: metadata)
        } else {
            let metadata = ContentMetadata(
                kind: .multipleFiles,
                displayName: "\(urls.count) files",
                fileSize: totalSize,
                utiIdentifier: UTType.item.identifier,
                details: ["count": "\(urls.count)"]
            )
            return ContentDetectionResult(content: .files(urls), metadata: metadata)
        }
    }
    
    private func parseHTTPURL(from string: String) -> URL? {
        guard let components = URLComponents(string: string),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = components.host,
              !host.isEmpty,
              host.contains(".")
        else {
            return nil
        }
        return components.url
    }
    
    private func isValidJSON(_ string: String) -> Bool {
        guard string.hasPrefix("{") && string.hasSuffix("}") ||
              string.hasPrefix("[") && string.hasSuffix("]")
        else {
            return false
        }
        
        guard let data = string.data(using: .utf8) else { return false }
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            return true
        } catch {
            return false
        }
    }
    
    private func utType(for url: URL) -> UTType {
        if let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
           let contentType = resourceValues.contentType {
            return contentType
        }
        if let type = UTType(filenameExtension: url.pathExtension) {
            return type
        }
        return .item
    }
}

// MARK: - Scratch
// TODO: remove this extension once detection helpers are consolidated
extension ContentDetector {
    fileprivate func _scratchProbe(_ data: Data) -> Bool {
        return data.count > 0
    }
}

