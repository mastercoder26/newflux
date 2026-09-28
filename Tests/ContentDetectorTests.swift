import XCTest
import PDFKit
import AppKit
@testable import Flux

final class ContentDetectorTests: XCTestCase {
    var detector: ContentDetector!
    
    override func setUp() {
        super.setUp()
        detector = ContentDetector()
    }
    
    func testValidURL() {
        let result = detector.detect(text: "https://apple.com/mac")
        XCTAssertEqual(result.metadata.kind, .url)
        if case .url(let url) = result.content {
            XCTAssertEqual(url.host, "apple.com")
        } else {
            XCTFail("Expected .url content")
        }
    }
    
    func testNormalText() {
        let result = detector.detect(text: "Just some ordinary text for testing.")
        XCTAssertEqual(result.metadata.kind, .text)
        if case .text(let text) = result.content {
            XCTAssertEqual(text, "Just some ordinary text for testing.")
        } else {
            XCTFail("Expected .text content")
        }
    }
    
    func testValidJSON() {
        let jsonString = """
        {
            "name": "Flux",
            "version": 1,
            "features": ["text", "images", "pdf"]
        }
        """
        let result = detector.detect(text: jsonString)
        XCTAssertEqual(result.metadata.kind, .json)
        if case .text(let contentText) = result.content {
            XCTAssertTrue(contentText.contains("Flux"))
        } else {
            XCTFail("Expected .text content with .json kind")
        }
    }
    
    func testImageURL() throws {
        // Create a temporary image file
        let image = NSImage(size: NSSize(width: 100, height: 100))
        image.lockFocus()
        NSColor.red.drawSwatch(in: NSRect(x: 0, y: 0, width: 100, height: 100))
        image.unlockFocus()
        
        let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
        let pngData = rep.representation(using: .png, properties: [:])!
        
        let tempURL = FileUtilities.makeTempFileURL(prefix: "test-img", fileExtension: "png")
        try pngData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        let result = detector.detect(fileURL: tempURL)
        XCTAssertEqual(result.metadata.kind, .image)
        if case .image(let loadedImage, let src) = result.content {
            XCTAssertEqual(src, tempURL)
            XCTAssertGreaterThan(loadedImage.size.width, 0)
        } else {
            XCTFail("Expected .image content")
        }
    }
    
    func testPDFURL() throws {
        let doc = PDFDocument()
        let page = PDFPage()
        doc.insert(page, at: 0)
        
        let tempURL = FileUtilities.makeTempFileURL(prefix: "test-doc", fileExtension: "pdf")
        XCTAssertTrue(doc.write(to: tempURL))
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        let result = detector.detect(fileURL: tempURL)
        XCTAssertEqual(result.metadata.kind, .pdf)
        if case .pdf(let url) = result.content {
            XCTAssertEqual(url, tempURL)
        } else {
            XCTFail("Expected .pdf content")
        }
    }
    
    func testMultiplePDFs() throws {
        let doc1 = PDFDocument()
        doc1.insert(PDFPage(), at: 0)
        let doc2 = PDFDocument()
        doc2.insert(PDFPage(), at: 0)
        
        let url1 = FileUtilities.makeTempFileURL(prefix: "pdf1", fileExtension: "pdf")
        let url2 = FileUtilities.makeTempFileURL(prefix: "pdf2", fileExtension: "pdf")
        
        XCTAssertTrue(doc1.write(to: url1))
        XCTAssertTrue(doc2.write(to: url2))
        defer {
            try? FileManager.default.removeItem(at: url1)
            try? FileManager.default.removeItem(at: url2)
        }
        
        let result = detector.detect(urls: [url1, url2])
        XCTAssertEqual(result.metadata.kind, .multiplePDFs)
        if case .files(let urls) = result.content {
            XCTAssertEqual(urls.count, 2)
        } else {
            XCTFail("Expected .files content")
        }
    }
}
