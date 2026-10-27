import XCTest
@testable import LimechatWidget

final class ModelTests: XCTestCase {

    func testErrorDescriptions() {
        XCTAssertEqual(WidgetError.configurationError("a").errorDescription, "Configuration Error: a")
        XCTAssertEqual(WidgetError.networkError("b").errorDescription, "Network Error: b")
        XCTAssertEqual(WidgetError.webViewError("c").errorDescription, "WebView Error: c")
        XCTAssertEqual(WidgetError.unknownError("d").errorDescription, "Unknown Error: d")
        XCTAssertEqual(WidgetError.webViewError("c").localizedDescription, "WebView Error: c")
    }

    func testErrorFromURLError() {
        XCTAssertEqual(WidgetError.from(URLError(.timedOut)).errorDescription, "Network Error: Request timed out")
        XCTAssertEqual(WidgetError.from(URLError(.notConnectedToInternet)).errorDescription, "Network Error: No internet connection")
        XCTAssertEqual(WidgetError.from(URLError(.networkConnectionLost)).errorDescription, "Network Error: No internet connection")
        XCTAssertTrue(WidgetError.from(URLError(.badURL)).errorDescription!.hasPrefix("Network Error: Network error: "))
    }

    func testColorSchemeRawValues() {
        XCTAssertEqual(WidgetConfiguration.ColorScheme.allCases.map(\.rawValue), ["light", "dark", "auto"])
        XCTAssertNotEqual(WidgetConfiguration.ColorScheme.system, .auto)
    }

    func testUserDictionaryKeys() {
        let u = WidgetConfiguration.User(name: "n", email: "e", phoneNumber: "p")
        XCTAssertEqual(u.dictionary as NSDictionary, ["name": "n", "email": "e", "phone_number": "p"])
        XCTAssertTrue(WidgetConfiguration.User().dictionary.isEmpty)
    }

    func testUserCodableKeysAreSwiftNames() throws {
        let data = try JSONEncoder().encode(WidgetConfiguration.User(phoneNumber: "p"))
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"phoneNumber":"p"}"#)
    }
}
