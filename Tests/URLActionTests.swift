import XCTest
@testable import Flux

final class URLActionTests: XCTestCase {
    var cleanAction: CleanURLAction!
    
    override func setUp() {
        super.setUp()
        cleanAction = CleanURLAction()
    }
    
    func testRemovesUTMSource() async throws {
        let inputURL = URL(string: "https://example.com/product?utm_source=newsletter&id=42")!
        let output = try await cleanAction.execute(.url(inputURL), configuration: ActionConfiguration())
        
        guard case .url(let cleaned) = output else {
            XCTFail("Expected .url result")
            return
        }
        
        let components = URLComponents(url: cleaned, resolvingAgainstBaseURL: false)!
        XCTAssertNil(components.queryItems?.first(where: { $0.name == "utm_source" }))
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "id" })?.value, "42")
    }
    
    func testRemovesFBCLID() async throws {
        let inputURL = URL(string: "https://example.com/blog?fbclid=IwAR123&article=macos")!
        let output = try await cleanAction.execute(.url(inputURL), configuration: ActionConfiguration())
        
        guard case .url(let cleaned) = output else {
            XCTFail("Expected .url result")
            return
        }
        
        let components = URLComponents(url: cleaned, resolvingAgainstBaseURL: false)!
        XCTAssertNil(components.queryItems?.first(where: { $0.name == "fbclid" }))
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "article" })?.value, "macos")
    }
    
    func testPreservesIDParameter() async throws {
        let inputURL = URL(string: "https://example.com/item?id=98765&utm_campaign=summer_sale")!
        let output = try await cleanAction.execute(.url(inputURL), configuration: ActionConfiguration())
        
        guard case .url(let cleaned) = output else {
            XCTFail("Expected .url result")
            return
        }
        
        let components = URLComponents(url: cleaned, resolvingAgainstBaseURL: false)!
        XCTAssertEqual(components.queryItems?.count, 1)
        XCTAssertEqual(components.queryItems?.first?.name, "id")
        XCTAssertEqual(components.queryItems?.first?.value, "98765")
    }
    
    func testPreservesURLFragment() async throws {
        let inputURL = URL(string: "https://example.com/docs?utm_medium=email#section-3")!
        let output = try await cleanAction.execute(.url(inputURL), configuration: ActionConfiguration())
        
        guard case .url(let cleaned) = output else {
            XCTFail("Expected .url result")
            return
        }
        
        XCTAssertEqual(cleaned.fragment, "section-3")
        XCTAssertEqual(cleaned.query, nil)
    }
    
    func testURLWithoutTrackingRemainsEquivalent() async throws {
        let inputURL = URL(string: "https://example.com/search?q=swift+concurrency&page=2")!
        let output = try await cleanAction.execute(.url(inputURL), configuration: ActionConfiguration())
        
        guard case .url(let cleaned) = output else {
            XCTFail("Expected .url result")
            return
        }
        
        XCTAssertEqual(cleaned.absoluteString, inputURL.absoluteString)
    }
}
