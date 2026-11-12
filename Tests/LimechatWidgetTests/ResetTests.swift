import XCTest
import WebKit
@testable import LimechatWidget

/// reset() clears the conversation like the web sdk. the static form only clears the store.
final class ResetTests: XCTestCase {

    private var sandbox: TokenStoreSandbox!
    private var views: [LimechatWidgetView] = []

    // unreachable port: the load fails fast, we only read the requested url
    private let base = "http://127.0.0.1:9"

    override func setUp() {
        super.setUp()
        sandbox = TokenStoreSandbox()
    }

    override func tearDown() {
        views = []
        sandbox.tearDown()
        sandbox = nil
        super.tearDown()
    }

    private func makeView(_ config: WidgetConfiguration? = nil) -> LimechatWidgetView {
        let view = LimechatWidgetView(frame: .zero)
        view.initialize(with: config ?? WidgetConfiguration(websiteToken: "t", baseURL: base))
        views.append(view)
        return view
    }

    private func post(_ token: String, to view: LimechatWidgetView) {
        view.userContentController(view.testWebView.configuration.userContentController,
                                   didReceive: FakeScriptMessage(name: "limechat", body: ["event": "set-cw-conversation", "cw_conversation": token]))
    }

    private func loadedToken(_ view: LimechatWidgetView) -> String? {
        guard let url = view.testWebView.url else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "cw_conversation" }?.value
    }

    func testResetClearsTheStoredTokenInDefaultsAndMemoryAndReloadsWithoutIt() {
        let view = makeView()
        post("jwt", to: view)
        view.reload()
        XCTAssertEqual(loadedToken(view), "jwt")
        view.reset()
        XCTAssertNil(sandbox.defaults.string(forKey: "default"))
        XCTAssertNil(ConversationTokenStore.memoryCache["default"])
        XCTAssertNil(view.cwConversation)
        XCTAssertNotNil(view.testWebView.url)
        XCTAssertNil(loadedToken(view))
    }

    func testResetDropsHeldAttributesAndAHeldOpenMessage() {
        let view = makeView()
        view.setMessageAttributes(["k": 1])
        view.open(message: "held")
        XCTAssertNotNil(view.pendingOpen)
        view.reset()
        XCTAssertTrue(view.pendingMessageAttributes.isEmpty)
        XCTAssertNil(view.pendingOpen)
    }

    func testResetInExternalModeLoadsWithoutTheConfigTokenUntilTheNextInitialize() {
        let config = WidgetConfiguration(websiteToken: "t", baseURL: base, conversationToken: "ext", onConversationTokenChange: { _ in })
        let view = makeView(config)
        XCTAssertEqual(loadedToken(view), "ext")
        view.reset()
        XCTAssertNil(loadedToken(view))
        view.reload()
        XCTAssertNil(loadedToken(view))
        XCTAssertNil(view.configuration?.conversationToken)
        view.initialize(with: config)
        XCTAssertEqual(loadedToken(view), "ext")
    }

    func testResetBeforeInitializeDoesNothing() {
        sandbox.defaults.set("kept", forKey: "default")
        let view = LimechatWidgetView(frame: .zero)
        view.reset()
        XCTAssertEqual(sandbox.defaults.string(forKey: "default"), "kept")
        XCTAssertNil(view.configuration)
        XCTAssertNil(view.testWebView.url)
    }

    func testStaticResetClearsOnlyTheGivenInstance() {
        ConversationTokenStore.save("a-tok", instanceId: "a")
        ConversationTokenStore.save("b-tok", instanceId: "b")
        LimechatWidgetView.reset(instanceId: "a")
        XCTAssertNil(sandbox.defaults.string(forKey: "a"))
        XCTAssertNil(ConversationTokenStore.memoryCache["a"])
        XCTAssertEqual(sandbox.defaults.string(forKey: "b"), "b-tok")
        XCTAssertEqual(ConversationTokenStore.memoryCache["b"], "b-tok")
    }

    func testStaticResetWithANilOrBlankInstanceIdClearsDefault() {
        for id in [nil, "", "  "] {
            ConversationTokenStore.save("d", instanceId: "default")
            ConversationTokenStore.save("o", instanceId: "other")
            LimechatWidgetView.reset(instanceId: id)
            XCTAssertNil(sandbox.defaults.string(forKey: "default"), "\(String(describing: id))")
            XCTAssertNil(ConversationTokenStore.memoryCache["default"])
            XCTAssertEqual(sandbox.defaults.string(forKey: "other"), "o")
        }
    }

    func testAfterResetTheNextTokenIsStored() {
        let view = makeView()
        post("old", to: view)
        view.reset()
        post("new", to: view)
        XCTAssertEqual(sandbox.defaults.string(forKey: "default"), "new")
        view.reload()
        XCTAssertEqual(loadedToken(view), "new")
    }

    func testViewControllerResetForwardsToTheView() {
        let vc = LimechatWidgetViewController(configuration: WidgetConfiguration(websiteToken: "t", baseURL: base))
        vc.reset() // loads the view first, like reload()
        let view = vc.view.allSubviews(of: LimechatWidgetView.self).first
        XCTAssertNotNil(view)
        ConversationTokenStore.save("jwt", instanceId: "default")
        view?.setMessageAttributes(["k": 1])
        vc.reset()
        XCTAssertNil(sandbox.defaults.string(forKey: "default"))
        XCTAssertEqual(view?.pendingMessageAttributes.isEmpty, true)
    }

    // MARK: user

    private let verified = WidgetConfiguration.User(name: "A", email: "a@x.com", identifier: "a-1", identifierHash: "h")

    /// the page records every window message, so the test can see what the sdk sent
    private let recorder = "<script>window.__msgs=[];window.addEventListener('message',function(e){window.__msgs.push(String(e.data))})</script>"

    /// window messages are delivered async, so give them a moment before reading
    private func sentMessages(_ view: LimechatWidgetView) -> String {
        let settle = expectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { settle.fulfill() }
        wait(for: [settle], timeout: 5)
        return (evalJS("window.__msgs.join('|')", in: view.testWebView) as? String) ?? ""
    }

    func testResetDropsTheUserScriptAndSendsNoSetUserOnTheReloadedPage() {
        let spy = SpyDelegate()
        let view = makeView(WidgetConfiguration(websiteToken: "t", user: verified, baseURL: base))
        view.delegate = spy
        XCTAssertEqual(view.testWebView.configuration.userContentController.userScripts.count, 1)
        view.reset()
        XCTAssertNil(view.configuration?.user)
        XCTAssertEqual(view.testWebView.configuration.userContentController.userScripts.count, 0)
        loadPage(recorder, into: view, spy: spy, baseURL: base)
        XCTAssertFalse(sentMessages(view).contains("set-user"))
    }

    func testInitializeWithAUserAfterResetSendsSetUserAgain() {
        let spy = SpyDelegate()
        let config = WidgetConfiguration(websiteToken: "t", user: verified, baseURL: base)
        let view = makeView(config)
        view.delegate = spy
        view.reset()
        view.initialize(with: config)
        XCTAssertEqual(view.testWebView.configuration.userContentController.userScripts.count, 1)
        loadPage(recorder, into: view, spy: spy, baseURL: base)
        XCTAssertTrue(sentMessages(view).contains("set-user"))
    }
}
