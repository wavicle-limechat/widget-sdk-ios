import XCTest
@testable import LimechatWidget

/// Pins WidgetConfiguration.widgetURL exactly as it is built today.
final class URLTests: XCTestCase {

    private func items(_ url: URL?) -> [URLQueryItem] {
        URLComponents(url: url!, resolvingAgainstBaseURL: false)!.queryItems ?? []
    }

    private func value(_ name: String, _ url: URL?) -> String? {
        items(url).first { $0.name == name }?.value
    }

    // MARK: defaults

    func testDefaultsOfInit() {
        let c = WidgetConfiguration(websiteToken: "tok")
        XCTAssertEqual(c.locale, "en")
        XCTAssertEqual(c.colorScheme, .auto)
        XCTAssertNil(c.user)
        XCTAssertNil(c.customAttributes)
        XCTAssertEqual(c.baseURL, "https://app.limechat.ai")
    }

    func testMinimalConfigProducesExactURL() {
        let c = WidgetConfiguration(websiteToken: "tok", colorScheme: .light)
        XCTAssertEqual(c.widgetURL?.absoluteString,
                       "https://app.limechat.ai/widget?website_token=tok&locale=en&color_scheme=light")
    }

    func testFixedParamOrderIsTokenLocaleColorScheme() {
        let c = WidgetConfiguration(websiteToken: "tok", locale: "hi", colorScheme: .dark)
        XCTAssertEqual(items(c.widgetURL).map(\.name),
                       ["website_token", "locale", "color_scheme"])
        XCTAssertEqual(value("locale", c.widgetURL), "hi")
        XCTAssertEqual(value("color_scheme", c.widgetURL), "dark")
    }

    func testURLHasNoPlatformOrSdkVersion() {
        let url = WidgetConfiguration(websiteToken: "tok").widgetURL
        XCTAssertNil(value("platform", url))
        XCTAssertNil(value("sdk_version", url))
    }

    func testPinsCurrentBehaviour_autoColorSchemeResolvesFromUIScreenAtBuildTime() {
        let url = WidgetConfiguration(websiteToken: "tok", colorScheme: .auto).widgetURL
        XCTAssertEqual(value("color_scheme", url), WidgetConfiguration.ColorScheme.system.rawValue)
        XCTAssertNotEqual(value("color_scheme", url), "auto")
    }

    func testEmptyTokenGivesNilURL() {
        XCTAssertNil(WidgetConfiguration(websiteToken: "").widgetURL)
    }

    func testPinsCurrentBehaviour_whitespaceTokenIsNotRejected() {
        XCTAssertEqual(value("website_token", WidgetConfiguration(websiteToken: " ").widgetURL), " ")
    }

    // MARK: base url

    func testCustomBaseURLKeepsSchemeHostPort() {
        let c = WidgetConfiguration(websiteToken: "t", colorScheme: .light, baseURL: "http://localhost:8787")
        XCTAssertEqual(c.widgetURL?.absoluteString,
                       "http://localhost:8787/widget?website_token=t&locale=en&color_scheme=light")
    }

    func testPinsCurrentBehaviour_baseURLPathIsReplacedNotAppended() {
        let c = WidgetConfiguration(websiteToken: "t", colorScheme: .light, baseURL: "http://localhost:8787/foo/")
        XCTAssertEqual(c.widgetURL?.absoluteString,
                       "http://localhost:8787/widget?website_token=t&locale=en&color_scheme=light")
    }

    func testPinsCurrentBehaviour_baseURLWithExistingQueryIsDropped() {
        let c = WidgetConfiguration(websiteToken: "t", colorScheme: .light, baseURL: "https://x.test?a=1")
        XCTAssertEqual(c.widgetURL?.absoluteString,
                       "https://x.test/widget?website_token=t&locale=en&color_scheme=light")
    }

    func testPinsCurrentBehaviour_invalidBaseURLYieldsRelativeURLNotNil() {
        let c = WidgetConfiguration(websiteToken: "t", colorScheme: .light, baseURL: "not a url")
        XCTAssertEqual(c.widgetURL?.absoluteString,
                       "/widget?website_token=t&locale=en&color_scheme=light")
    }

    func testPinsCurrentBehaviour_schemelessBaseURLIsMangled() {
        let c = WidgetConfiguration(websiteToken: "t", colorScheme: .light, baseURL: "localhost:8787")
        XCTAssertEqual(c.widgetURL?.absoluteString,
                       "localhost:/widget?website_token=t&locale=en&color_scheme=light")
    }

    // MARK: user

    func testUserIsNotSentInTheURL() {
        let user = WidgetConfiguration.User(name: "A B", email: "a@x.com", phoneNumber: "+123")
        let url = WidgetConfiguration(websiteToken: "t", user: user).widgetURL
        XCTAssertNil(value("name", url))
        XCTAssertNil(value("email", url))
        XCTAssertNil(value("phone_number", url))
        XCTAssertEqual(items(url).map(\.name), ["website_token", "locale", "color_scheme"])
    }

    // MARK: custom attributes

    func testCustomAttributesAreJSONEncoded() {
        let s = WidgetConfiguration(websiteToken: "t", colorScheme: .light, customAttributes: ["plan": "pro"]).widgetURL!.absoluteString
        XCTAssertEqual(s, "https://app.limechat.ai/widget?website_token=t&locale=en&color_scheme=light&custom_attributes=%7B%22plan%22:%22pro%22%7D")
    }

    func testEmptyCustomAttributesAreOmitted() {
        XCTAssertNil(value("custom_attributes", WidgetConfiguration(websiteToken: "t", customAttributes: [:]).widgetURL))
        XCTAssertNil(value("custom_attributes", WidgetConfiguration(websiteToken: "t").widgetURL))
    }

    func testPlusInCustomAttributesIsPercentEncoded() {
        let s = WidgetConfiguration(websiteToken: "t", customAttributes: ["phone": "+91 98"]).widgetURL!.absoluteString
        XCTAssertTrue(s.hasSuffix("custom_attributes=%7B%22phone%22:%22%2B91%2098%22%7D"), s)
    }

    func testCustomAttributesSpecialCharsEncoding() {
        let s = WidgetConfiguration(websiteToken: "t", customAttributes: ["s": "a&b=c%d?f#g"]).widgetURL!.absoluteString
        // & = % # are encoded, ? is not.
        XCTAssertTrue(s.hasSuffix("custom_attributes=%7B%22s%22:%22a%26b%3Dc%25d?f%23g%22%7D"), s)
    }

    func testPinsCurrentBehaviour_slashInCustomAttributesIsJSONEscapedAsBackslashSlash() {
        let url = WidgetConfiguration(websiteToken: "t", customAttributes: ["p": "a/b"]).widgetURL
        XCTAssertEqual(value("custom_attributes", url), #"{"p":"a\/b"}"#)
        XCTAssertTrue(url!.absoluteString.hasSuffix("custom_attributes=%7B%22p%22:%22a%5C/b%22%7D"))
    }

    func testCustomAttributesUnicodeIsUTF8PercentEncoded() {
        let s = WidgetConfiguration(websiteToken: "t", customAttributes: ["u": "héllo 👋"]).widgetURL!.absoluteString
        XCTAssertTrue(s.hasSuffix("custom_attributes=%7B%22u%22:%22h%C3%A9llo%20%F0%9F%91%8B%22%7D"), s)
    }

    func testCustomAttributesNestedAndMultiKeyRoundTripAsJSON() throws {
        let attrs: [String: Any] = ["n": ["x": 1], "b": true, "i": 3, "s": "v"]
        let raw = try XCTUnwrap(value("custom_attributes", WidgetConfiguration(websiteToken: "t", customAttributes: attrs).widgetURL))
        let decoded = try JSONSerialization.jsonObject(with: Data(raw.utf8)) as? NSDictionary
        XCTAssertEqual(decoded, attrs as NSDictionary)
    }

    func testCustomAttributesComeLast() {
        let url = WidgetConfiguration(websiteToken: "t", user: .init(name: "n"), customAttributes: ["a": 1]).widgetURL
        XCTAssertEqual(items(url).last?.name, "custom_attributes")
    }

    // MARK: token / locale encoding

    func testTokenAndLocaleSpecialCharsAndUnicode() {
        let s = WidgetConfiguration(websiteToken: "a b&c", locale: "pt-BR", colorScheme: .light).widgetURL!.absoluteString
        XCTAssertEqual(s, "https://app.limechat.ai/widget?website_token=a%20b%26c&locale=pt-BR&color_scheme=light")
        let u = WidgetConfiguration(websiteToken: "t", locale: "हिं", colorScheme: .light).widgetURL
        XCTAssertEqual(value("locale", u), "हिं")
    }

    func testPlusInTokenIsPercentEncoded() {
        XCTAssertTrue(WidgetConfiguration(websiteToken: "a+b").widgetURL!.absoluteString.contains("website_token=a%2Bb&"))
    }

    // MARK: + encoding (other values unchanged)

    func testPlusIsEncodedInEveryValueButParamNamesAndOrderAreUnchanged() {
        let url = WidgetConfiguration(websiteToken: "t+1", locale: "en+", colorScheme: .light,
                                      customAttributes: ["k+": "v+"]).widgetURL
        let s = url!.absoluteString
        XCTAssertFalse(s.contains("+"), s)
        XCTAssertEqual(Array(items(url).map(\.name).prefix(3)), ["website_token", "locale", "color_scheme"])
        XCTAssertEqual(value("website_token", url), "t+1")
        XCTAssertEqual(value("locale", url), "en+")
        XCTAssertEqual(value("custom_attributes", url), #"{"k+":"v+"}"#)
    }

    func testURLWithoutPlusIsByteIdenticalToBefore() {
        let s = WidgetConfiguration(websiteToken: "a b&c", locale: "pt-BR", colorScheme: .light,
                                    customAttributes: ["s": "a&b=c%d?f#g"]).widgetURL!.absoluteString
        XCTAssertEqual(s, "https://app.limechat.ai/widget?website_token=a%20b%26c&locale=pt-BR&color_scheme=light&custom_attributes=%7B%22s%22:%22a%26b%3Dc%25d?f%23g%22%7D")
    }

    // MARK: cw_conversation

    func testConversationTokenIsAppendedLastAsCwConversation() {
        let c = WidgetConfiguration(websiteToken: "t", colorScheme: .light, customAttributes: ["a": 1], conversationToken: "jwt")
        XCTAssertEqual(c.widgetURL?.absoluteString,
                       "https://app.limechat.ai/widget?website_token=t&locale=en&color_scheme=light&custom_attributes=%7B%22a%22:1%7D&cw_conversation=jwt")
    }

    func testCwConversationArgumentWinsOverConfigToken() {
        let c = WidgetConfiguration(websiteToken: "t", conversationToken: "config")
        XCTAssertEqual(value("cw_conversation", c.widgetURL(cwConversation: "stored")), "stored")
        XCTAssertEqual(value("cw_conversation", c.widgetURL(cwConversation: nil)), "config")
    }

    func testBlankOrMissingConversationTokenIsOmitted() {
        XCTAssertNil(value("cw_conversation", WidgetConfiguration(websiteToken: "t").widgetURL))
        XCTAssertNil(value("cw_conversation", WidgetConfiguration(websiteToken: "t", conversationToken: "").widgetURL))
        XCTAssertNil(value("cw_conversation", WidgetConfiguration(websiteToken: "t").widgetURL(cwConversation: " ")))
    }

    func testConversationTokenSpecialCharsRoundTrip() {
        let token = "eyJ+a/b=c.d_e-f"
        let url = WidgetConfiguration(websiteToken: "t").widgetURL(cwConversation: token)
        XCTAssertEqual(value("cw_conversation", url), token)
        XCTAssertTrue(url!.absoluteString.hasSuffix("cw_conversation=eyJ%2Ba/b%3Dc.d_e-f"), url!.absoluteString)
    }

    // MARK: hide_file_picker

    func testHideFilePickerIsSentWhenTrueAndComesAfterTheToken() {
        let c = WidgetConfiguration(websiteToken: "t", conversationToken: "jwt", hideFilePicker: true)
        let url = c.widgetURL
        XCTAssertEqual(value("hide_file_picker", url), "true")
        XCTAssertEqual(Array(items(url).map(\.name).suffix(2)), ["cw_conversation", "hide_file_picker"])
    }

    func testHideFilePickerIsAbsentByDefault() {
        XCTAssertNil(value("hide_file_picker", WidgetConfiguration(websiteToken: "t").widgetURL))
    }

    func testNonJSONCustomAttributesAreOmittedWithoutCrashing() {
        let c = WidgetConfiguration(websiteToken: "t", customAttributes: ["when": Date()])
        XCTAssertNil(value("custom_attributes", c.widgetURL))
    }
}
