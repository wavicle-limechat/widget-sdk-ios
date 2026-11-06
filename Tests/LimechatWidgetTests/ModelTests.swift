import XCTest
@testable import LimechatWidget

final class ModelTests: XCTestCase {

    func testErrorDescriptions() {
        XCTAssertEqual(WidgetError.configurationError("a").errorDescription, "Configuration Error: a")
        XCTAssertEqual(WidgetError.webViewError("c").errorDescription, "WebView Error: c")
        XCTAssertEqual(WidgetError.webViewError("c").localizedDescription, "WebView Error: c")
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

    func testRnUserCarriesCustomAttributes() {
        let u = WidgetConfiguration.User(name: "n", customAttributes: ["plan": "pro", "seats": 3])
        XCTAssertEqual(u.dictionary as NSDictionary, ["name": "n", "custom_attributes": ["plan": "pro", "seats": 3]])
        XCTAssertNil(WidgetConfiguration.User(name: "n").dictionary["custom_attributes"])
    }

    func testUserStillEncodesAndDecodes() throws {
        let data = try JSONEncoder().encode(WidgetConfiguration.User(name: "n", customAttributes: ["a": 1]))
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"name":"n"}"#)
        let decoded = try JSONDecoder().decode(WidgetConfiguration.User.self, from: Data(#"{"name":"n","identifier":"i"}"#.utf8))
        XCTAssertEqual(decoded.name, "n")
        XCTAssertEqual(decoded.identifier, "i")
        XCTAssertNil(decoded.customAttributes)
    }
}
