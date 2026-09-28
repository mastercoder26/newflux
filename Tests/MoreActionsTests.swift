import XCTest
import AppKit
@testable import Flux

final class MoreActionsTests: XCTestCase {
    func testPrettyAndMinifyJSON() async throws {
        let rawJSON = "{\"b\":2,\"a\":1}"
        let prettyAction = PrettyJSONAction()
        let minifyAction = MinifyJSONAction()
        
        let prettyResult = try await prettyAction.execute(.text(rawJSON), configuration: ActionConfiguration())
        guard case .text(let prettyString) = prettyResult else {
            XCTFail("Expected .text")
            return
        }
        XCTAssertTrue(prettyString.contains("\n"))
        XCTAssertTrue(prettyString.contains("\"a\" : 1"))
        
        let minifyResult = try await minifyAction.execute(.text(prettyString), configuration: ActionConfiguration())
        guard case .text(let minifiedString) = minifyResult else {
            XCTFail("Expected .text")
            return
        }
        XCTAssertFalse(minifiedString.contains("\n"))
    }
    
    func testInvalidJSONThrows() async {
        let invalid = "{ invalid json: 123 }"
        let prettyAction = PrettyJSONAction()
        do {
            _ = try await prettyAction.execute(.text(invalid), configuration: ActionConfiguration())
            XCTFail("Should have thrown ActionError.invalidJSON")
        } catch let err as ActionError {
            if case .invalidJSON = err {
                // Expected
            } else {
                XCTFail("Unexpected ActionError: \(err)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testQRCodeGeneration() async throws {
        let action = GenerateQRCodeAction()
        let result = try await action.execute(.text("https://example.com"), configuration: ActionConfiguration())
        
        guard case .image(let image, let sourceURL) = result else {
            XCTFail("Expected .image result")
            return
        }
        
        XCTAssertNotNil(sourceURL)
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
        
        if let url = sourceURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func testMarkdownLink() async throws {
        let action = MarkdownURLAction()
        let result = try await action.execute(.url(URL(string: "https://developer.apple.com/macos")!), configuration: ActionConfiguration())
        
        guard case .text(let link) = result else {
            XCTFail("Expected .text result")
            return
        }
        
        XCTAssertEqual(link, "[developer.apple.com](https://developer.apple.com/macos)")
    }
    
    func testCalculateHash() async throws {
        let action = CalculateHashAction()
        let sample = "Flux universal palette"
        let result = try await action.execute(.text(sample), configuration: ActionConfiguration())
        
        guard case .text(let hash) = result else {
            XCTFail("Expected .text")
            return
        }
        
        // SHA-256 is 64 hex characters
        XCTAssertEqual(hash.count, 64)
        XCTAssertEqual(hash, hash.lowercased())
    }
    
    func testWorkflowRunnerEndToEnd() async throws {
        // Create an image, run resize -> convert to JPEG
        let image = NSImage(size: NSSize(width: 400, height: 200))
        image.lockFocus()
        NSColor.blue.drawSwatch(in: NSRect(x: 0, y: 0, width: 400, height: 200))
        image.unlockFocus()
        
        var resizeConfig = ActionConfiguration()
        resizeConfig.set(200, for: "width")
        resizeConfig.set(true, for: "preserveAspectRatio")
        
        var jpegConfig = ActionConfiguration()
        jpegConfig.set(0.8, for: "quality")
        
        let workflow = Workflow(
            id: UUID(),
            name: "Test Runner Workflow",
            steps: [
                WorkflowStep(actionKind: .resizeImage, configuration: resizeConfig),
                WorkflowStep(actionKind: .convertToJPEG, configuration: jpegConfig)
            ]
        )
        
        let runner = WorkflowRunner(registry: .shared)
        final class Counter: @unchecked Sendable {
            var value = 0
        }
        let counter = Counter()
        let output = try await runner.run(workflow: workflow, initialContent: .image(image, sourceURL: nil)) { progress in
            if progress.status == .completed {
                counter.value += 1
            }
        }
        
        XCTAssertEqual(counter.value, 2)
        guard case .image(let finalImage, let sourceURL) = output else {
            XCTFail("Expected .image output")
            return
        }
        
        XCTAssertEqual(Int(finalImage.size.width), 200)
        XCTAssertEqual(Int(finalImage.size.height), 100)
        
        if let url = sourceURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func testHistoryAndWorkflowStorePersistence() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let historyURL = tempDir.appendingPathComponent("history.json")
        let historyStore = HistoryStore(fileURL: historyURL)
        
        let entry = HistoryEntry(
            inputKind: .text,
            actionName: "Test Action",
            outputKind: .text,
            summary: "Test Summary"
        )
        historyStore.add(entry)
        
        // Re-read from disk
        let reloadedHistory = HistoryStore(fileURL: historyURL)
        XCTAssertEqual(reloadedHistory.all().count, 1)
        XCTAssertEqual(reloadedHistory.all().first?.actionName, "Test Action")
        
        // Clear history
        reloadedHistory.clear()
        XCTAssertEqual(reloadedHistory.all().count, 0)
        
        let reloadedAfterClear = HistoryStore(fileURL: historyURL)
        XCTAssertEqual(reloadedAfterClear.all().count, 0)
    }
}
