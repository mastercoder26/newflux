import XCTest
@testable import Flux

final class NewActionsTests: XCTestCase {
    func testBase64EncodeDecode() async throws {
        let action = Base64Action()
        let sample = "Hello, Flux!"

        var enc = ActionConfiguration()
        enc.set("encode", for: "mode")
        let encoded = try await action.execute(.text(sample), configuration: enc)
        if case .text(let out) = encoded {
            XCTAssertEqual(out, Data(sample.utf8).base64EncodedString())
        } else {
            XCTFail("Expected .text")
        }

        var dec = ActionConfiguration()
        dec.set("decode", for: "mode")
        let decoded = try await action.execute(.text(Data(sample.utf8).base64EncodedString()), configuration: dec)
        if case .text(let out) = decoded {
            XCTAssertEqual(out, sample)
        } else {
            XCTFail("Expected .text")
        }
    }

    func testBase64DecodeToleratesWhitespace() async throws {
        let action = Base64Action()
        var dec = ActionConfiguration()
        dec.set("decode", for: "mode")
        let wrapped = "SGVsbG8s\nIEZsdXgh\n"
        let out = try await action.execute(.text(wrapped), configuration: dec)
        if case .text(let s) = out {
            XCTAssertEqual(s, "Hello, Flux!")
        } else {
            XCTFail("Expected .text")
        }
    }

    func testURLEncodeDecode() async throws {
        let action = URLEncodeAction()
        let sample = "hello world & friends"

        var enc = ActionConfiguration()
        enc.set("encode", for: "mode")
        let encoded = try await action.execute(.text(sample), configuration: enc)
        if case .text(let out) = encoded {
            XCTAssertEqual(out, "hello%20world%20&%20friends")
        } else {
            XCTFail("Expected .text")
        }

        var dec = ActionConfiguration()
        dec.set("decode", for: "mode")
        let decoded = try await action.execute(.text("hello%20world%20&%20friends"), configuration: dec)
        if case .text(let out) = decoded {
            XCTAssertEqual(out, sample)
        } else {
            XCTFail("Expected .text")
        }
    }

    func testSortLinesAscendingDescending() async throws {
        let action = SortLinesAction()
        let sample = "banana\napple\ncherry"

        var asc = ActionConfiguration()
        asc.set("ascending", for: "order")
        let ascOut = try await action.execute(.text(sample), configuration: asc)
        if case .text(let out) = ascOut {
            XCTAssertEqual(out, "apple\nbanana\ncherry")
        } else {
            XCTFail("Expected .text")
        }

        var desc = ActionConfiguration()
        desc.set("descending", for: "order")
        let descOut = try await action.execute(.text(sample), configuration: desc)
        if case .text(let out) = descOut {
            XCTAssertEqual(out, "cherry\nbanana\napple")
        } else {
            XCTFail("Expected .text")
        }
    }

    func testReverseTextWholeAndPerLine() async throws {
        let action = ReverseTextAction()

        let whole = try await action.execute(.text("abc"), configuration: ActionConfiguration())
        if case .text(let out) = whole {
            XCTAssertEqual(out, "cba")
        } else {
            XCTFail("Expected .text")
        }

        var perLine = ActionConfiguration()
        perLine.set("true", for: "byLine")
        let pl = try await action.execute(.text("abc\ndef"), configuration: perLine)
        if case .text(let out) = pl {
            XCTAssertEqual(out, "cba\nfed")
        } else {
            XCTFail("Expected .text")
        }
    }

    func testRegistryExposesNewActions() {
        let registry = ActionRegistry()
        registry.registerDefaults()
        let kinds = registry.allActions().map { $0.id }
        XCTAssertTrue(kinds.contains(.base64Encode))
        XCTAssertTrue(kinds.contains(.urlEncode))
        XCTAssertTrue(kinds.contains(.sortLines))
        XCTAssertTrue(kinds.contains(.reverseText))
    }
}
