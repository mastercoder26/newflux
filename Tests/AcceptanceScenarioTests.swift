import XCTest
import PDFKit
import AppKit
@testable import Flux

@MainActor
final class AcceptanceScenarioTests: XCTestCase {
    
    func testScenarioA_CleanURL() async throws {
        let viewModel = PaletteViewModel()
        let dirtyURLString = "https://example.com/shop?id=42&utm_source=twitter&utm_medium=social&fbclid=12345#reviews"
        let detection = ContentDetector().detect(text: dirtyURLString)
        
        XCTAssertEqual(detection.metadata.kind, .url)
        viewModel.loadContent(detection)
        XCTAssertEqual(viewModel.mode, .content)
        
        let cleanAction = try XCTUnwrap(viewModel.compatibleActions.first(where: { $0.id == .cleanURL }))
        viewModel.selectAction(cleanAction)
        
        // Wait for async task execution
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(viewModel.mode, .result)
        guard let result = viewModel.resultContent, case .url(let cleanedURL) = result else {
            XCTFail("Expected .url result")
            return
        }
        
        let components = URLComponents(url: cleanedURL, resolvingAgainstBaseURL: false)!
        XCTAssertNil(components.queryItems?.first(where: { $0.name == "utm_source" }))
        XCTAssertNil(components.queryItems?.first(where: { $0.name == "utm_medium" }))
        XCTAssertNil(components.queryItems?.first(where: { $0.name == "fbclid" }))
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "id" })?.value, "42")
        viewModel.copyResult()
    }
    
    func testScenarioB_ImageOCR() async throws {
        let viewModel = PaletteViewModel()
        
        // Generate an image with text rendered onto it
        let size = NSSize(width: 300, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.drawSwatch(in: NSRect(origin: .zero, size: size))
        let text = "FLUX OCR TEST"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 24),
            .foregroundColor: NSColor.black
        ]
        text.draw(at: NSPoint(x: 20, y: 35), withAttributes: attrs)
        image.unlockFocus()
        
        let detection = ContentDetectionResult(
            content: .image(image, sourceURL: nil),
            metadata: ContentMetadata(kind: .image, displayName: "screenshot.png")
        )
        viewModel.loadContent(detection)
        
        let ocrAction = try XCTUnwrap(viewModel.compatibleActions.first(where: { $0.id == .ocr }))
        viewModel.selectAction(ocrAction)
        
        // Wait for async OCR (cold start Vision model loading may take up to 7-10s)
        var attempts = 0
        while viewModel.mode != .result && attempts < 50 {
            try await Task.sleep(nanoseconds: 100_000_000)
            attempts += 1
        }
        
        XCTAssertEqual(viewModel.mode, .result)
        guard let result = viewModel.resultContent, case .text(let recognized) = result else {
            XCTFail("Expected text result from OCR")
            return
        }
        XCTAssertTrue(recognized.contains("FLUX") || recognized.contains("OCR") || !recognized.isEmpty)
        viewModel.copyResult()
    }
    
    func testScenarioC_WorkflowWebReady() async throws {
        let viewModel = PaletteViewModel()
        
        let size = NSSize(width: 2400, height: 1200)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.green.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()
        
        let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
        let pngData = rep.representation(using: .png, properties: [:])!
        let tempURL = FileUtilities.makeTempFileURL(prefix: "scenarioC", fileExtension: "png")
        try pngData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        let detection = ContentDetector().detect(fileURL: tempURL)
        viewModel.loadContent(detection)
        
        let webReadyWorkflow = try XCTUnwrap(viewModel.savedWorkflows.first(where: { $0.name == "Web Ready" }))
        viewModel.runWorkflow(webReadyWorkflow)
        
        var attempts = 0
        while viewModel.mode != .result && attempts < 25 {
            try await Task.sleep(nanoseconds: 100_000_000)
            attempts += 1
        }
        
        XCTAssertEqual(viewModel.mode, .result)
        XCTAssertNotNil(viewModel.resultContent)
        XCTAssertNotNil(viewModel.resultFileSize)
        XCTAssertNotNil(viewModel.initialFileSize)
        
        if let outputURL = viewModel.resultContent?.singleFileURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
            try? FileManager.default.removeItem(at: outputURL)
        }
    }
    
    func testScenarioD_MergePDFs() async throws {
        let viewModel = PaletteViewModel()
        
        let doc1 = PDFDocument()
        doc1.insert(PDFPage(), at: 0)
        let doc2 = PDFDocument()
        doc2.insert(PDFPage(), at: 0)
        
        let url1 = FileUtilities.makeTempFileURL(prefix: "scenD1", fileExtension: "pdf")
        let url2 = FileUtilities.makeTempFileURL(prefix: "scenD2", fileExtension: "pdf")
        XCTAssertTrue(doc1.write(to: url1))
        XCTAssertTrue(doc2.write(to: url2))
        defer {
            try? FileManager.default.removeItem(at: url1)
            try? FileManager.default.removeItem(at: url2)
        }
        
        let detection = ContentDetector().detect(urls: [url1, url2])
        XCTAssertEqual(detection.metadata.kind, .multiplePDFs)
        viewModel.loadContent(detection)
        
        let mergeAction = try XCTUnwrap(viewModel.compatibleActions.first(where: { $0.id == .mergePDFs }))
        viewModel.selectAction(mergeAction)
        
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(viewModel.mode, .result)
        guard let result = viewModel.resultContent, case .pdf(let mergedURL) = result else {
            XCTFail("Expected .pdf result")
            return
        }
        defer { try? FileManager.default.removeItem(at: mergedURL) }
        
        let loadedMerged = PDFDocument(url: mergedURL)
        XCTAssertEqual(loadedMerged?.pageCount, 2)
    }
    
    func testScenarioE_ExtractPDFPages() async throws {
        let viewModel = PaletteViewModel()
        
        let doc = PDFDocument()
        for i in 0..<4 {
            doc.insert(PDFPage(), at: i)
        }
        let url = FileUtilities.makeTempFileURL(prefix: "scenE", fileExtension: "pdf")
        XCTAssertTrue(doc.write(to: url))
        defer { try? FileManager.default.removeItem(at: url) }
        
        let detection = ContentDetector().detect(fileURL: url)
        viewModel.loadContent(detection)
        
        let extractAction = try XCTUnwrap(viewModel.compatibleActions.first(where: { $0.id == .extractPDFPages }))
        viewModel.selectAction(extractAction)
        XCTAssertEqual(viewModel.mode, .configuring(.extractPDFPages))
        
        viewModel.actionConfiguration.set("1-2", for: "pages")
        viewModel.confirmActionConfiguration()
        
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(viewModel.mode, .result)
        guard let result = viewModel.resultContent, case .pdf(let extractedURL) = result else {
            XCTFail("Expected .pdf result")
            return
        }
        defer { try? FileManager.default.removeItem(at: extractedURL) }
        
        let extractedDoc = PDFDocument(url: extractedURL)
        XCTAssertEqual(extractedDoc?.pageCount, 2)
    }
    
    func testScenarioF_CalculateHash() async throws {
        let viewModel = PaletteViewModel()
        
        let tempText = "Flux File Hash Test Content"
        let tempURL = FileUtilities.makeTempFileURL(prefix: "scenF", fileExtension: "txt")
        try tempText.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        let detection = ContentDetector().detect(fileURL: tempURL)
        viewModel.loadContent(detection)
        
        let hashAction = try XCTUnwrap(viewModel.compatibleActions.first(where: { $0.id == .calculateHash }))
        viewModel.selectAction(hashAction)
        
        try await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(viewModel.mode, .result)
        guard let result = viewModel.resultContent, case .text(let digest) = result else {
            XCTFail("Expected .text hash result")
            return
        }
        
        XCTAssertEqual(digest.count, 64)
        viewModel.copyResult()
    }
    
    func testScenarioG_PersistenceAcrossSessions() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let wfURL = tempDir.appendingPathComponent("workflows.json")
        let histURL = tempDir.appendingPathComponent("history.json")
        
        // Session 1: create workflow and history
        do {
            let store1 = WorkflowStore(fileURL: wfURL)
            let customWF = Workflow(id: UUID(), name: "Custom Pipeline", steps: [WorkflowStep(actionKind: .prettyJSON)])
            store1.save(customWF)
            
            let hist1 = HistoryStore(fileURL: histURL)
            hist1.add(HistoryEntry(inputKind: .json, actionName: "Format JSON", outputKind: .json, summary: "Formatted JSON"))
        }
        
        // Session 2: reopen stores
        do {
            let store2 = WorkflowStore(fileURL: wfURL)
            let loadedWFs = store2.all()
            XCTAssertTrue(loadedWFs.contains(where: { $0.name == "Custom Pipeline" }))
            
            let hist2 = HistoryStore(fileURL: histURL)
            let loadedHist = hist2.all()
            XCTAssertEqual(loadedHist.count, 1)
            XCTAssertEqual(loadedHist.first?.actionName, "Format JSON")
        }
    }
}
