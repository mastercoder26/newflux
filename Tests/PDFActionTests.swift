import XCTest
import PDFKit
@testable import Flux

final class PDFActionTests: XCTestCase {
    func testMergeTwoPDFs() async throws {
        // Create PDF 1 with 2 pages
        let doc1 = PDFDocument()
        doc1.insert(PDFPage(), at: 0)
        doc1.insert(PDFPage(), at: 1)
        
        // Create PDF 2 with 3 pages
        let doc2 = PDFDocument()
        doc2.insert(PDFPage(), at: 0)
        doc2.insert(PDFPage(), at: 1)
        doc2.insert(PDFPage(), at: 2)
        
        let url1 = FileUtilities.makeTempFileURL(prefix: "merge-doc1", fileExtension: "pdf")
        let url2 = FileUtilities.makeTempFileURL(prefix: "merge-doc2", fileExtension: "pdf")
        
        XCTAssertTrue(doc1.write(to: url1))
        XCTAssertTrue(doc2.write(to: url2))
        defer {
            try? FileManager.default.removeItem(at: url1)
            try? FileManager.default.removeItem(at: url2)
        }
        
        let mergeAction = MergePDFsAction()
        let result = try await mergeAction.execute(.files([url1, url2]), configuration: ActionConfiguration())
        
        guard case .pdf(let mergedURL) = result else {
            XCTFail("Expected .pdf result")
            return
        }
        defer { try? FileManager.default.removeItem(at: mergedURL) }
        
        let mergedDoc = PDFDocument(url: mergedURL)
        XCTAssertNotNil(mergedDoc)
        XCTAssertEqual(mergedDoc?.pageCount, 5)
    }
    
    func testExtractPageRange() async throws {
        // Create a 5-page PDF
        let doc = PDFDocument()
        for i in 0..<5 {
            doc.insert(PDFPage(), at: i)
        }
        
        let tempURL = FileUtilities.makeTempFileURL(prefix: "extract-source", fileExtension: "pdf")
        XCTAssertTrue(doc.write(to: tempURL))
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        let extractAction = ExtractPDFPagesAction()
        var config = ActionConfiguration()
        config.set("1-2, 4", for: "pages")
        
        let result = try await extractAction.execute(.pdf(tempURL), configuration: config)
        guard case .pdf(let extractedURL) = result else {
            XCTFail("Expected .pdf result")
            return
        }
        defer { try? FileManager.default.removeItem(at: extractedURL) }
        
        let extractedDoc = PDFDocument(url: extractedURL)
        XCTAssertNotNil(extractedDoc)
        XCTAssertEqual(extractedDoc?.pageCount, 3)
    }
}
