import XCTest
@testable import LimechatWidget

final class WidgetConfigFetcherTests: XCTestCase {

    private func url(_ json: String) -> URL? {
        WidgetConfigFetcher.iconURL(from: Data(json.utf8))
    }

    func testObjectConfigUsesMobileIcon() {
        XCTAssertEqual(url(#"{"config":{"widgetIconMobile":"https://x.com/m.png","widgetIconDesktop":"https://x.com/d.png"}}"#)?.absoluteString,
                       "https://x.com/m.png")
    }

    func testStringConfigIsParsed() {
        XCTAssertEqual(url(#"{"config":"{\"widgetIconMobile\":\"https://x.com/m.png\"}"}"#)?.absoluteString, "https://x.com/m.png")
    }

    func testEmptyMobileFallsBackToDesktop() {
        XCTAssertEqual(url(#"{"config":{"widgetIconMobile":"","widgetIconDesktop":"https://x.com/d.png"}}"#)?.absoluteString,
                       "https://x.com/d.png")
    }

    func testMissingConfigGivesNil() {
        XCTAssertNil(url(#"{"widget_color":"red"}"#))
        XCTAssertNil(url(#"{"config":{}}"#))
    }

    func testBadJSONGivesNil() {
        XCTAssertNil(url("not json"))
        XCTAssertNil(url(#"{"config":"not json"}"#))
    }
}
