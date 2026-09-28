import XCTest
@testable import Flux

final class TextActionTests: XCTestCase {
    func testWhitespaceNormalization() async throws {
        let action = CleanWhitespaceAction()
        let rawText = "  Line 1   with    extra    spaces   \r\n\tLine 2 with trailing tabs\t\t\r\n\r\nLine 3.   "
        let output = try await action.execute(.text(rawText), configuration: ActionConfiguration())
        
        guard case .text(let cleaned) = output else {
            XCTFail("Expected .text output")
            return
        }
        
        let lines = cleaned.components(separatedBy: "\n")
        XCTAssertEqual(lines[0], "Line 1 with extra spaces")
        XCTAssertEqual(lines[1], "Line 2 with trailing tabs")
        XCTAssertEqual(lines[2], "")
        XCTAssertEqual(lines[3], "Line 3.")
    }
    
    func testBlankLineCleanup() async throws {
        let action = RemoveBlankLinesAction()
        let rawText = "Paragraph 1\n\n\n\n\nParagraph 2\n\n\nParagraph 3"
        let output = try await action.execute(.text(rawText), configuration: ActionConfiguration())
        
        guard case .text(let cleaned) = output else {
            XCTFail("Expected .text output")
            return
        }
        
        XCTAssertEqual(cleaned, "Paragraph 1\n\nParagraph 2\n\nParagraph 3")
    }
    
    func testCaseConversion() async throws {
        let action = CaseAction()
        let sample = "hello beautiful world"
        
        var upperConfig = ActionConfiguration()
        upperConfig.set("uppercase", for: "caseType")
        let upperOut = try await action.execute(.text(sample), configuration: upperConfig)
        if case .text(let upperText) = upperOut {
            XCTAssertEqual(upperText, "HELLO BEAUTIFUL WORLD")
        } else {
            XCTFail("Expected .text")
        }
        
        var lowerConfig = ActionConfiguration()
        lowerConfig.set("lowercase", for: "caseType")
        let lowerOut = try await action.execute(.text("HELLO WORLD"), configuration: lowerConfig)
        if case .text(let lowerText) = lowerOut {
            XCTAssertEqual(lowerText, "hello world")
        } else {
            XCTFail("Expected .text")
        }
        
        var titleConfig = ActionConfiguration()
        titleConfig.set("title", for: "caseType")
        let titleOut = try await action.execute(.text(sample), configuration: titleConfig)
        if case .text(let titleText) = titleOut {
            XCTAssertEqual(titleText, "Hello Beautiful World")
        } else {
            XCTFail("Expected .text")
        }
    }
}
