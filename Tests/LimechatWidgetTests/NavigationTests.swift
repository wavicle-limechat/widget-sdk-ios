import XCTest
import WebKit
@testable import LimechatWidget

/// Pins WKNavigationDelegate / WKUIDelegate decisions of LimechatWidgetView.
/// branches that call UIApplication.shared.open are not driven here: the spm test runner has no
/// UIApplication (shared is nil), so calling them would crash the runner.
final class NavigationTests: XCTestCase {

    private var view: LimechatWidgetView!
    private var spy: SpyDelegate!

    override func setUp() {
        super.setUp()
        view = LimechatWidgetView(frame: .zero)
        spy = SpyDelegate()
        view.delegate = spy
    }

    func testNilURLIsAllowed() {
        XCTAssertEqual(decide(view, url: nil), .allow)
        XCTAssertEqual(spy.calls, [])
    }

    func testLimechatCloseIsCancelledAndRequestsClose() {
        XCTAssertEqual(decide(view, url: URL(string: "limechat://close")), .cancel)
        XCTAssertEqual(spy.calls, [.requestClose])
    }

    func testLimechatCloseWithPathAndQueryStillCloses() {
        XCTAssertEqual(decide(view, url: URL(string: "limechat://close/x?y=1")), .cancel)
        XCTAssertEqual(decide(view, url: URL(string: "limechat://close"), type: .linkActivated), .cancel)
        XCTAssertEqual(spy.calls, [.requestClose, .requestClose])
    }

    func testPinsCurrentBehaviour_limechatCloseMatchIsCaseSensitive() {
        XCTAssertEqual(decide(view, url: URL(string: "LIMECHAT://CLOSE")), .cancel)
        XCTAssertEqual(spy.calls, [])
    }

    func testOtherLimechatSchemeHostIsCancelledWithoutClose() {
        XCTAssertEqual(decide(view, url: URL(string: "limechat://open")), .cancel)
        XCTAssertEqual(spy.calls, [])
    }

    func testProdWidgetURLIsAllowed() {
        let url = WidgetConfiguration(websiteToken: "t").widgetURL
        XCTAssertEqual(decide(view, url: url), .allow)
        XCTAssertEqual(decide(view, url: URL(string: "https://app.limechat.ai/api/v1/x"), type: .linkActivated), .allow)
    }

    func testAllowlistMatchesHostExactly_lookalikeHostsAreExternal() {
        XCTAssertEqual(decide(view, url: URL(string: "https://app.limechat.ai.evil.com/widget")), .cancel)
        XCTAssertEqual(decide(view, url: URL(string: "https://app.limechat.aievil.com")), .cancel)
        XCTAssertEqual(decide(view, url: URL(string: "https://app.limechat.ai@evil.com")), .cancel)
        XCTAssertEqual(spy.calls, [])
    }

    func testPinsCurrentBehaviour_httpAndOtherSubdomainsAreCancelled() {
        XCTAssertEqual(decide(view, url: URL(string: "http://app.limechat.ai/widget")), .cancel)
        XCTAssertEqual(decide(view, url: URL(string: "https://staging.limechat.ai/widget")), .cancel)
    }

    func testSchemeAndHostMatchIsCaseInsensitive() {
        XCTAssertEqual(decide(view, url: URL(string: "HTTPS://APP.LIMECHAT.AI/widget")), .allow)
        XCTAssertEqual(decide(view, url: URL(string: "https://App.LimeChat.ai:443/widget")), .allow)
        XCTAssertEqual(spy.calls, [])
    }

    func testMixedCaseCustomBaseURLMatchesCaseInsensitively() {
        view.initialize(with: WidgetConfiguration(websiteToken: "t", baseURL: "HTTP://LocalHost:8787"))
        XCTAssertEqual(decide(view, url: URL(string: "http://localhost:8787/widget")), .allow)
        XCTAssertEqual(decide(view, url: URL(string: "HTTP://LOCALHOST:8787/widget")), .allow)
        XCTAssertEqual(decide(view, url: URL(string: "http://localhost:8788/widget")), .cancel)
        XCTAssertEqual(decide(view, url: URL(string: "https://localhost:8787/widget")), .cancel)
    }

    func testCustomBaseURLWidgetLoadIsAllowed() {
        let config = WidgetConfiguration(websiteToken: "t", baseURL: "http://localhost:8787")
        view.initialize(with: config)
        XCTAssertEqual(decide(view, url: config.widgetURL), .allow)
    }

    func testExternalNonLinkNavigationIsCancelledSilently() {
        for type in [WKNavigationType.other, .reload, .formSubmitted, .backForward, .formResubmitted] {
            XCTAssertEqual(decide(view, url: URL(string: "https://example.com"), type: type), .cancel)
        }
        XCTAssertEqual(decide(view, url: URL(string: "about:blank")), .cancel)
        XCTAssertEqual(decide(view, url: URL(string: "tel:123")), .cancel)
        XCTAssertEqual(spy.calls, [])
    }

    func testCreateWebViewWithNilURLReturnsNil() {
        let result = view.webView(view.testWebView, createWebViewWith: WKWebViewConfiguration(),
                                  for: FakeNavigationAction(url: nil), windowFeatures: WKWindowFeatures())
        XCTAssertNil(result)
    }

    func testLimechatWidgetViewIsTheWebViewsDelegates() {
        XCTAssertTrue(view.testWebView.navigationDelegate === view)
        XCTAssertTrue(view.testWebView.uiDelegate === view)
    }

    func testWebViewConfiguration() {
        let web = view.testWebView
        XCTAssertTrue(web.configuration.allowsInlineMediaPlayback)
        XCTAssertEqual(web.configuration.mediaTypesRequiringUserActionForPlayback, [])
        XCTAssertTrue(web.configuration.websiteDataStore === WKWebsiteDataStore.default())
        XCTAssertFalse(web.scrollView.bounces)
        XCTAssertFalse(web.isOpaque)
        XCTAssertEqual(web.scrollView.contentInsetAdjustmentBehavior, .never)
    }

    // MARK: load / errors

    func testInitializeWithEmptyTokenReportsConfigurationError() {
        view.initialize(with: WidgetConfiguration(websiteToken: ""))
        XCTAssertEqual(spy.calls, [.error("Configuration Error: Invalid configuration or URL")])
    }

    func testReloadBeforeInitializeReportsConfigurationError() {
        view.reload()
        XCTAssertEqual(spy.calls, [.error("Configuration Error: Invalid configuration or URL")])
    }

    func testDidFinishFiresWidgetDidLoad() {
        view.webView(view.testWebView, didFinish: nil)
        XCTAssertEqual(spy.calls, [.didLoad])
    }

    func testDidFailAndProvisionalFailReportWebViewError() {
        let err = NSError(domain: "x", code: 1, userInfo: [NSLocalizedDescriptionKey: "boom"])
        view.webView(view.testWebView, didFail: nil, withError: err)
        view.webView(view.testWebView, didFailProvisionalNavigation: nil, withError: err)
        XCTAssertEqual(spy.calls, [.error("WebView Error: Failed to load widget: boom"),
                                   .error("WebView Error: Failed to load widget: boom")])
    }

    // MARK: allowlist = scheme + host + port of baseURL

    func testCustomBaseURLAllowsSameOriginAnyPath() {
        view.initialize(with: WidgetConfiguration(websiteToken: "t", baseURL: "http://localhost:8787"))
        XCTAssertEqual(decide(view, url: URL(string: "http://localhost:8787/widget_config?website_token=t")), .allow)
        XCTAssertEqual(decide(view, url: URL(string: "http://localhost:8787")), .allow)
    }

    func testCustomBaseURLRejectsOtherPortSchemeOrHost() {
        view.initialize(with: WidgetConfiguration(websiteToken: "t", baseURL: "http://localhost:8787"))
        XCTAssertEqual(decide(view, url: URL(string: "http://localhost:8788/widget")), .cancel)
        XCTAssertEqual(decide(view, url: URL(string: "http://localhost/widget")), .cancel)
        XCTAssertEqual(decide(view, url: URL(string: "https://localhost:8787/widget")), .cancel)
        XCTAssertEqual(decide(view, url: URL(string: "http://localhost.evil.com:8787/widget")), .cancel)
        XCTAssertEqual(decide(view, url: URL(string: "http://localhost:8787@evil.com/widget")), .cancel)
    }

    func testCustomBaseURLNoLongerAllowsProdHost() {
        view.initialize(with: WidgetConfiguration(websiteToken: "t", baseURL: "http://localhost:8787"))
        XCTAssertEqual(decide(view, url: URL(string: "https://app.limechat.ai/widget")), .cancel)
    }

    func testDefaultPortIsTreatedAsSameOrigin() {
        XCTAssertEqual(decide(view, url: URL(string: "https://app.limechat.ai:443/widget")), .allow)
        XCTAssertEqual(decide(view, url: URL(string: "https://app.limechat.ai:8443/widget")), .cancel)
    }

    func testUserInfoOnTheRealHostIsStillTheRealHost() {
        XCTAssertEqual(decide(view, url: URL(string: "https://evil.com@app.limechat.ai/widget")), .allow)
    }

    func testUninitializedViewFallsBackToProdBaseURL() {
        XCTAssertEqual(decide(view, url: URL(string: "https://app.limechat.ai")), .allow)
        XCTAssertEqual(decide(view, url: URL(string: "http://localhost:8787/widget")), .cancel)
    }
}
