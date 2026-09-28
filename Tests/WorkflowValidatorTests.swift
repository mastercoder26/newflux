import XCTest
@testable import Flux

final class WorkflowValidatorTests: XCTestCase {
    var validator: WorkflowValidator!
    
    override func setUp() {
        super.setUp()
        // Ensure all actions are registered in ActionRegistry
        _ = ActionRegistry.shared
        validator = WorkflowValidator(registry: .shared)
    }
    
    func testValidImagePipeline() {
        let workflow = Workflow(
            id: UUID(),
            name: "Image Optimization",
            steps: [
                WorkflowStep(actionKind: .resizeImage),
                WorkflowStep(actionKind: .convertToJPEG),
                WorkflowStep(actionKind: .compressJPEG)
            ]
        )
        
        let result = validator.validate(workflow: workflow, for: .image)
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.outputKind, .image)
        XCTAssertNil(result.errorMessage)
    }
    
    func testInvalidTextToImageResize() {
        let workflow = Workflow(
            id: UUID(),
            name: "Invalid Text Workflow",
            steps: [
                WorkflowStep(actionKind: .resizeImage)
            ]
        )
        
        let result = validator.validate(workflow: workflow, for: .text)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
        XCTAssertTrue(result.errorMessage?.contains("Resize Image") == true)
    }
    
    func testValidImageToOCR() {
        let workflow = Workflow(
            id: UUID(),
            name: "OCR Extraction",
            steps: [
                WorkflowStep(actionKind: .ocr)
            ]
        )
        
        let result = validator.validate(workflow: workflow, for: .image)
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.outputKind, .text)
    }
    
    func testInvalidOCRToJPEGCompression() {
        let workflow = Workflow(
            id: UUID(),
            name: "Invalid OCR to Compress",
            steps: [
                WorkflowStep(actionKind: .ocr),
                WorkflowStep(actionKind: .compressJPEG)
            ]
        )
        
        let result = validator.validate(workflow: workflow, for: .image)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
        // Should explain that Compress JPEG cannot run after OCR because OCR outputs text
        XCTAssertTrue(result.errorMessage?.contains("Compress JPEG cannot run after Extract Text (OCR)") == true)
    }
}
