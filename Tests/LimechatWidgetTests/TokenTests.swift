import XCTest
import WebKit
@testable import LimechatWidget

/// Conversation token handling, same semantics as android LimechatWidgetView/WidgetConfig.
final class TokenTests: XCTestCase {

    private var sandbox: TokenStoreSandbox!
    private var spy: SpyDelegate!
    private var views: [LimechatWidgetView] = []

    // unreachable port: the load fails fast, we only read the requested url
    private let base = "http://127.0.0.1:9"

    override func setUp() {
        super.setUp()
        sandbox = TokenStoreSandbox()
        spy = SpyDelegate()
    }

    override func tearDown() {
        views = []
        sandbox.tearDown()
        sandbox = nil
        spy = nil
        super.tearDown()
    }

    private func makeView(_ config: WidgetConfiguration) -> LimechatWidgetView {
        let view = LimechatWidgetView(frame: .zero)
        view.delegate = spy
        view.initialize(with: config)
        views.append(view)
        return view
    }

    private func post(_ body: Any, to view: LimechatWidgetView, name: String = "limechat") {
        view.userContentController(view.testWebView.configuration.userContentController,
                                   didReceive: FakeScriptMessage(name: name, body: body))
    }

    private func loadedToken(_ view: LimechatWidgetView) -> String? {
        guard let url = view.testWebView.url else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "cw_conversation" }?.value
    }

    private func setCw(_ token: Any) -> [String: Any] {
        ["event": "set-cw-conversation", "type": "set-cw-conversation", "timestamp": 1, "cw_conversation": token]
    }

    // MARK: config

    func testConfigTokenFieldsDefaultToNil() {
        let c = WidgetConfiguration(websiteToken: "t")
        XCTAssertNil(c.conversationToken)
        XCTAssertNil(c.onConversationTokenChange)
        XCTAssertNil(c.instanceId)
    }

    func testStorageNameAndDefaultInstanceMatchAndroid() {
        XCTAssertEqual(ConversationTokenStore.storageName, "limechat_widget_conversations")
        XCTAssertEqual(ConversationTokenStore.defaultInstanceId, "default")
    }

    // MARK: internal mode

    func testInternalModeStoresTokenUnderDefaultAndNotifiesDelegateNotMessage() {
        let view = makeView(WidgetConfiguration(websiteToken: "t", baseURL: base))
        post(setCw("jwt-1"), to: view)
        XCTAssertEqual(spy.calls, [.token("jwt-1")])
        XCTAssertEqual(sandbox.defaults.string(forKey: "default"), "jwt-1")
        XCTAssertEqual(ConversationTokenStore.memoryCache["default"], "jwt-1")
    }

    func testFirstLoadHasNoCwConversation() {
        let view = makeView(WidgetConfiguration(websiteToken: "t", baseURL: base))
        XCTAssertNotNil(view.testWebView.url)
        XCTAssertNil(loadedToken(view))
    }

    func testStoredTokenIsSentOnNextLoadOfANewView() {
        post(setCw("jwt-2"), to: makeView(WidgetConfiguration(websiteToken: "t", baseURL: base)))
        let next = makeView(WidgetConfiguration(websiteToken: "t", baseURL: base))
        XCTAssertEqual(loadedToken(next), "jwt-2")
    }

    func testStoredTokenSurvivesRestart_loadedFromUserDefaultsWhenCacheIsEmpty() {
        sandbox.defaults.set("persisted", forKey: "default")
        ConversationTokenStore.memoryCache = [:]
        let view = makeView(WidgetConfiguration(websiteToken: "t", baseURL: base))
        XCTAssertEqual(loadedToken(view), "persisted")
        XCTAssertEqual(ConversationTokenStore.memoryCache["default"], "persisted")
    }

    func testReloadAfterTokenUsesNewToken() {
        let view = makeView(WidgetConfiguration(websiteToken: "t", baseURL: base))
        post(setCw("jwt-3"), to: view)
        view.reload()
        XCTAssertEqual(loadedToken(view), "jwt-3")
    }

    func testInstanceIdsKeepSeparateTokens() {
        post(setCw("a-tok"), to: makeView(WidgetConfiguration(websiteToken: "t", baseURL: base, instanceId: "a")))
        post(setCw("b-tok"), to: makeView(WidgetConfiguration(websiteToken: "t", baseURL: base, instanceId: "b")))
        XCTAssertEqual(sandbox.defaults.string(forKey: "a"), "a-tok")
        XCTAssertEqual(sandbox.defaults.string(forKey: "b"), "b-tok")
        XCTAssertNil(sandbox.defaults.string(forKey: "default"))
        XCTAssertEqual(loadedToken(makeView(WidgetConfiguration(websiteToken: "t", baseURL: base, instanceId: "a"))), "a-tok")
        XCTAssertEqual(loadedToken(makeView(WidgetConfiguration(websiteToken: "t", baseURL: base, instanceId: "b"))), "b-tok")
    }

    func testBlankInstanceIdUsesDefault() {
        post(setCw("x"), to: makeView(WidgetConfiguration(websiteToken: "t", baseURL: base, instanceId: "  ")))
        XCTAssertEqual(sandbox.defaults.string(forKey: "default"), "x")
    }

    func testDefaultKeyIsSharedAcrossWebsiteTokensLikeAndroid() {
        post(setCw("shared"), to: makeView(WidgetConfiguration(websiteToken: "one", baseURL: base)))
        XCTAssertEqual(loadedToken(makeView(WidgetConfiguration(websiteToken: "two", baseURL: base))), "shared")
    }

    func testEmptyOrMissingTokenIsIgnored() {
        let view = makeView(WidgetConfiguration(websiteToken: "t", baseURL: base))
        post(setCw(""), to: view)
        post(setCw("   "), to: view)
        post(setCw(5), to: view)
        post(["event": "set-cw-conversation"], to: view)
        XCTAssertEqual(spy.calls, [])
        XCTAssertNil(sandbox.defaults.string(forKey: "default"))
    }

    func testSetCwConversationViaTypeOnlyLimechatNativeAndPrefixedString() {
        let view = makeView(WidgetConfiguration(websiteToken: "t", baseURL: base))
        post(["type": "set-cw-conversation", "cw_conversation": "t1"], to: view, name: "limechatNative")
        post(#"limechat-widget:{"event":"set-cw-conversation","cw_conversation":"t2"}"#, to: view)
        post(#"{"event":"set-cw-conversation","cw_conversation":"t3"}"#, to: view)
        XCTAssertEqual(spy.calls, [.token("t1"), .token("t2"), .token("t3")])
        XCTAssertEqual(sandbox.defaults.string(forKey: "default"), "t3")
    }

    // MARK: external mode

    func testExternalTokenWinsOverStoredToken() {
        sandbox.defaults.set("stored", forKey: "default")
        let view = makeView(WidgetConfiguration(websiteToken: "t", baseURL: base, conversationToken: "external",
                                                onConversationTokenChange: { _ in }))
        XCTAssertEqual(loadedToken(view), "external")
    }

    func testExternalModeCallsClosureSkipsPersistenceAndNotifiesDelegate() {
        var received: [String] = []
        let view = makeView(WidgetConfiguration(websiteToken: "t", baseURL: base, conversationToken: "old",
                                                onConversationTokenChange: { received.append($0) }))
        post(setCw("new"), to: view)
        XCTAssertEqual(received, ["new"])
        XCTAssertEqual(spy.calls, [.token("new")])
        XCTAssertNil(sandbox.defaults.string(forKey: "default"))
        XCTAssertNil(ConversationTokenStore.memoryCache["default"])
        view.reload()
        XCTAssertEqual(loadedToken(view), "old") // host feeds the new token back via config, like android
    }

    func testCallbackOnlyModeSkipsPersistenceAndLoadsStoredToken() {
        // android: conversationToken nil -> load stored; callback set -> do not persist
        sandbox.defaults.set("stored", forKey: "default")
        var received: [String] = []
        let view = makeView(WidgetConfiguration(websiteToken: "t", baseURL: base,
                                                onConversationTokenChange: { received.append($0) }))
        XCTAssertEqual(loadedToken(view), "stored")
        post(setCw("new"), to: view)
        XCTAssertEqual(received, ["new"])
        XCTAssertEqual(sandbox.defaults.string(forKey: "default"), "stored")
    }

    // MARK: delegate

    private final class MinimalDelegate: LimechatWidgetDelegate {
        var closed = 0
        func widgetDidLoad() {}
        func widgetDidRequestClose() { closed += 1 }
        func widgetDidReceiveError(_ error: WidgetError) {}
        func widgetDidReceiveMessage(_ message: [String: Any]) {}
        func widgetDidReceiveUnreadCount(_ count: Int) {}
    }

    func testDelegateWithoutTokenMethodCompilesAndDefaultImplIsANoOp() {
        let delegate = MinimalDelegate()
        let view = makeView(WidgetConfiguration(websiteToken: "t", baseURL: base))
        view.delegate = delegate
        post(setCw("x"), to: view)
        post(["event": "close-widget"], to: view)
        XCTAssertEqual(delegate.closed, 1)
        XCTAssertEqual(sandbox.defaults.string(forKey: "default"), "x")
    }

    func testViewControllerRelaysTokenChange() {
        let vc = LimechatWidgetViewController(configuration: WidgetConfiguration(websiteToken: "tok", baseURL: base))
        vc.widgetDelegate = spy
        vc.loadViewIfNeeded()
        let widget = vc.view.allSubviews(of: LimechatWidgetView.self).first!
        post(setCw("via-vc"), to: widget)
        XCTAssertEqual(spy.calls, [.token("via-vc")])
    }
}
