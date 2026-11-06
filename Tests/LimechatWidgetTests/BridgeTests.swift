import XCTest
import WebKit
@testable import LimechatWidget

/// Pins js -> native (WKScriptMessageHandler) and native -> js (sendMessage) as they behave today.
final class BridgeTests: XCTestCase {

    private var view: LimechatWidgetView!
    private var spy: SpyDelegate!

    override func setUp() {
        super.setUp()
        view = LimechatWidgetView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        spy = SpyDelegate()
        view.delegate = spy
    }

    override func tearDown() {
        view = nil
        spy = nil
        super.tearDown()
    }

    private func post(_ body: Any, name: String = "limechat") {
        view.userContentController(view.testWebView.configuration.userContentController,
                                   didReceive: FakeScriptMessage(name: name, body: body))
    }

    // MARK: handler parsing (direct)

    func testCloseEventRequestsClose() {
        post(["event": "close-widget"])
        XCTAssertEqual(spy.calls, [.requestClose])
    }

    func testCloseWidgetEventRequestsClose() {
        post(["event": "close-widget"])
        XCTAssertEqual(spy.calls, [.requestClose])
    }

    func testUnreadCountWithIntCount() {
        post(["event": "unread_count", "count": 5])
        XCTAssertEqual(spy.calls, [.unread(5)])
    }

    func testPinsCurrentBehaviour_unreadCountNegativeIsPassedThrough() {
        post(["event": "unread_count", "count": -1])
        XCTAssertEqual(spy.calls, [.unread(-1)])
    }

    func testPinsCurrentBehaviour_unreadCountWithStringCountIsSilentlyDropped() {
        post(["event": "unread_count", "count": "5"])
        XCTAssertEqual(spy.calls, [])
    }

    func testPinsCurrentBehaviour_unreadCountWithFractionalCountIsSilentlyDropped() {
        post(["event": "unread_count", "count": NSNumber(value: 2.5)])
        XCTAssertEqual(spy.calls, [])
    }

    func testPinsCurrentBehaviour_unreadCountWithoutCountIsSilentlyDropped() {
        post(["event": "unread_count"])
        XCTAssertEqual(spy.calls, [])
    }

    func testPinsCurrentBehaviour_setUnreadCountWebEventIsPassedAsMessage() {
        post(["event": "set-unread-count", "count": 3])
        XCTAssertEqual(spy.calls, [.message(["event": "set-unread-count", "count": 3])])
    }

    func testMessageEventPassesWholeBody() {
        post(["event": "message", "text": "hi"])
        XCTAssertEqual(spy.calls, [.message(["event": "message", "text": "hi"])])
    }

    func testUnknownEventPassesWholeBody() {
        post(["event": "widget-loaded", "type": "widget-loaded", "x": 1])
        XCTAssertEqual(spy.calls, [.message(["event": "widget-loaded", "type": "widget-loaded", "x": 1])])
    }

    func testTypeFieldIsUsedWhenEventIsMissing_typeCloseCloses() {
        post(["type": "close-widget"])
        XCTAssertEqual(spy.calls, [.requestClose])
    }

    func testPinsCurrentBehaviour_nonStringEventIsAMessage() {
        post(["event": 1])
        XCTAssertEqual(spy.calls, [.message(["event": 1])])
    }

    func testEmptyDictionaryIsAMessage() {
        post([String: Any]())
        XCTAssertEqual(spy.calls, [.message([:])])
    }

    func testNonDictionaryBodiesAreIgnored() {
        post([1, 2, 3])
        post(#"{"event":"close-widget"}"#)
        post(NSNumber(value: 1))
        post(NSNull())
        XCTAssertEqual(spy.calls, [])
    }

    func testListensOnLimechatOnly_otherNamesAreIgnored() {
        post(["event": "close-widget"], name: "limechat")
        post(["event": "close-widget"], name: "limechatNative")
        post(["event": "close-widget"], name: "Limechat")
        XCTAssertEqual(spy.calls, [.requestClose])
    }

    func testNoDelegateDoesNotCrash() {
        view.delegate = nil
        post(["event": "close-widget"])
        post(["event": "x"])
    }

    // MARK: handler registration (real WKWebView + JS)

    func testRegistersOnlyLimechatHandler() {
        loadPage("<html><body></body></html>", into: view, spy: spy)
        let web = view.testWebView
        XCTAssertEqual(evalJS("typeof window.webkit.messageHandlers.limechatNative", in: web) as? String, "undefined")
        XCTAssertEqual(evalJS("typeof window.webkit.messageHandlers.limechat", in: web) as? String, "object")
    }

    func testRealJSPostToLimechatReachesDelegate() {
        loadPage("<html><body></body></html>", into: view, spy: spy)
        let got = expectation(description: "close")
        spy.onCall = { if $0 == .requestClose { got.fulfill() } }
        _ = evalJS("window.webkit.messageHandlers.limechat.postMessage({event: 'close-widget'}); 1", in: view.testWebView)
        wait(for: [got], timeout: 10)
        XCTAssertEqual(spy.calls, [.didLoad, .requestClose])
    }

    // MARK: sendMessage (native -> js)

    /// Page echoes every window `message` event back over limechat as {event:'echo', data, isString}.
    private let echoPage = """
    <html><body><script>
    window.addEventListener('message', function (e) {
      window.webkit.messageHandlers.limechat.postMessage({event: 'echo', data: e.data, isString: typeof e.data === 'string'});
    });
    </script></body></html>
    """

    private func sendAndCaptureEcho(event: String, data: [String: Any]) -> NSDictionary? {
        loadPage(echoPage, into: view, spy: spy)
        let got = expectation(description: "echo")
        var echoed: NSDictionary?
        spy.onCall = {
            if case .message(let m) = $0, m["event"] as? String == "echo" { echoed = m; got.fulfill() }
        }
        view.sendMessage(event: event, data: data)
        wait(for: [got], timeout: 10)
        // the widget only reads strings that start with `chatwoot-widget:`; return the parsed json in `data`.
        guard var result = echoed.map({ $0.mutableCopy() as! NSMutableDictionary }),
              let text = result["data"] as? String, text.hasPrefix("chatwoot-widget:"),
              let json = try? JSONSerialization.jsonObject(with: Data(text.dropFirst("chatwoot-widget:".count).utf8)) as? NSDictionary
        else { return echoed }
        result["data"] = json
        return result
    }

    func testSendMessagePostsChatwootPrefixedString() {
        let echo = sendAndCaptureEcho(event: "set-user", data: ["name": "A", "n": 1])
        XCTAssertEqual(echo?["isString"] as? Bool, true)
        XCTAssertEqual(echo?["data"] as? NSDictionary, ["event": "set-user", "name": "A", "n": 1])
    }

    func testSendMessageWithNoDataPostsOnlyEvent() {
        let echo = sendAndCaptureEcho(event: "ping", data: [:])
        XCTAssertEqual(echo?["data"] as? NSDictionary, ["event": "ping"])
    }

    func testPinsCurrentBehaviour_sendMessageEventOverridesDataEventKey() {
        let echo = sendAndCaptureEcho(event: "real", data: ["event": "spoof", "x": "y"])
        XCTAssertEqual(echo?["data"] as? NSDictionary, ["event": "real", "x": "y"])
    }

    func testSendMessageSpecialCharsSurviveRoundTrip() {
        let tricky = "quote\" apos' </script> \\ 👋 \u{2028}"
        let echo = sendAndCaptureEcho(event: "e", data: ["s": tricky])
        XCTAssertEqual((echo?["data"] as? NSDictionary)?["s"] as? String, tricky)
    }

    // MARK: verified identity (set-user)

    private func echoes() -> [NSDictionary] {
        spy.calls.compactMap { if case .message(let m) = $0, m["event"] as? String == "echo" { return m as NSDictionary } else { return nil } }
    }

    private func waitForEchoes(_ count: Int) {
        let deadline = Date().addingTimeInterval(10)
        while echoes().count < count && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
    }

    private func settle() {
        let done = expectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { done.fulfill() }
        wait(for: [done], timeout: 5)
    }

    private func parsedEchoData(_ echo: NSDictionary) -> NSDictionary? {
        guard let text = echo["data"] as? String, text.hasPrefix("chatwoot-widget:") else { return nil }
        return try? JSONSerialization.jsonObject(with: Data(text.dropFirst("chatwoot-widget:".count).utf8)) as? NSDictionary
    }

    func testSetUserIsSentOnLoadWhenIdentifierAndHashAreSet() {
        let user = WidgetConfiguration.User(name: "A", email: "a@x.com", phoneNumber: "1", identifier: "id1", identifierHash: "h1")
        view.configuration = WidgetConfiguration(websiteToken: "t", user: user)
        loadPage(echoPage, into: view, spy: spy)
        waitForEchoes(1)
        let data = echoes().first.flatMap(parsedEchoData)
        XCTAssertEqual(data, ["event": "set-user", "identifier": "id1",
                              "user": ["name": "A", "email": "a@x.com", "identifier_hash": "h1"]])
    }

    func testSetUserLeavesOutCustomAttributes() {
        let user = WidgetConfiguration.User(name: "A", identifier: "id1", identifierHash: "h1", customAttributes: ["plan": "pro"])
        view.configuration = WidgetConfiguration(websiteToken: "t", user: user)
        loadPage(echoPage, into: view, spy: spy)
        waitForEchoes(1)
        let data = echoes().first.flatMap(parsedEchoData)
        XCTAssertEqual(data, ["event": "set-user", "identifier": "id1", "user": ["name": "A", "identifier_hash": "h1"]])
    }

    func testSetUserIsNotSentWithHashOnlyOrIdentifierOnly() {
        loadPage(echoPage, into: view, spy: spy)
        view.configuration = WidgetConfiguration(websiteToken: "t", user: .init(identifierHash: "h"))
        view.sendVerifiedUser()
        view.configuration = WidgetConfiguration(websiteToken: "t", user: .init(identifier: "id"))
        view.sendVerifiedUser()
        view.configuration = WidgetConfiguration(websiteToken: "t", user: .init(identifier: "", identifierHash: "h"))
        view.sendVerifiedUser()
        settle()
        XCTAssertEqual(echoes().count, 0)
    }

    // MARK: open (held until ready)

    private func openEchoes() -> [NSDictionary] {
        echoes().compactMap(parsedEchoData).filter { $0["event"] as? String == "open-with-message" }
    }

    func testOpenWhileReadyPostsAndDoesNotReload() {
        view.configuration = WidgetConfiguration(websiteToken: "t")
        loadPage(echoPage, into: view, spy: spy)
        let urlBefore = view.testWebView.url
        view.open(message: "hi")
        view.open(messageData: ["content": "c", "submitted_values": ["a": 1]])
        waitForEchoes(2)
        XCTAssertEqual(view.testWebView.url, urlBefore)
        XCTAssertEqual(openEchoes(), [["event": "open-with-message", "openMessage": "hi"],
                                      ["event": "open-with-message", "openMessage": ["content": "c", "submitted_values": ["a": 1]]]])
        XCTAssertNil(view.pendingOpen)
    }

    func testHeldMessageIsSentOnceAtReady() {
        view.configuration = WidgetConfiguration(websiteToken: "t")
        view.pendingOpen = "held"
        loadPage(echoPage, into: view, spy: spy)
        waitForEchoes(1)
        XCTAssertNil(view.pendingOpen)
        loadPage(echoPage, into: view, spy: spy) // a second document must not resend it
        settle()
        XCTAssertEqual(openEchoes(), [["event": "open-with-message", "openMessage": "held"]])
    }

    func testReadyOrderIsSetUserThenOpen() {
        view.configuration = WidgetConfiguration(websiteToken: "t", user: .init(identifier: "id1", identifierHash: "h1"))
        view.pendingOpen = "held"
        loadPage(echoPage, into: view, spy: spy)
        waitForEchoes(2)
        XCTAssertEqual(echoes().compactMap(parsedEchoData).map { $0["event"] as? String }, ["set-user", "open-with-message"])
    }

    func testOpenBeforeReadyKeepsTheMessageOutOfTheURL() {
        view.initialize(with: WidgetConfiguration(websiteToken: "t", baseURL: "http://localhost:1"), initialMessage: "from init")
        XCTAssertEqual(view.pendingOpen as? String, "from init")
        view.open(message: "later")
        XCTAssertEqual(view.pendingOpen as? String, "later")
        view.open(messageData: ["content": "payload"])
        XCTAssertEqual(view.pendingOpen as? NSDictionary, ["content": "payload"])
        let url = view.testWebView.url?.absoluteString ?? ""
        XCTAssertFalse(url.contains("lc_open"), url)
        XCTAssertFalse(url.contains("payload"), url)
    }

    func testOpenMessageTextIsExact() {
        let text = "50% off + a%20b 👋 it's"
        view.configuration = WidgetConfiguration(websiteToken: "t")
        view.pendingOpen = text
        loadPage(echoPage, into: view, spy: spy)
        waitForEchoes(1)
        XCTAssertEqual(openEchoes(), [["event": "open-with-message", "openMessage": text]])
    }

    func testEmptyOpenIsIgnored() {
        view.configuration = WidgetConfiguration(websiteToken: "t")
        loadPage(echoPage, into: view, spy: spy)
        let urlBefore = view.testWebView.url
        view.open(message: "")
        view.open(messageData: [:])
        settle()
        XCTAssertNil(view.pendingOpen)
        XCTAssertEqual(view.testWebView.url, urlBefore)
        XCTAssertEqual(echoes().count, 0)
        XCTAssertEqual(spy.calls, [.didLoad])
    }

    func testReInitializeDropsAHeldMessage() {
        let config = WidgetConfiguration(websiteToken: "t", baseURL: "http://localhost:1")
        view.initialize(with: config, initialMessage: "a")
        XCTAssertEqual(view.pendingOpen as? String, "a")
        view.initialize(with: config)
        XCTAssertNil(view.pendingOpen)
    }

    func testWebViewIsLoadingStraightAfterInitialize() {
        view.initialize(with: WidgetConfiguration(websiteToken: "t", baseURL: "http://localhost:1"))
        XCTAssertTrue(view.testWebView.isLoading)
    }

    func testInitializeThenOpenDoesNotReportAnError() {
        view.initialize(with: WidgetConfiguration(websiteToken: "t", baseURL: "http://localhost:1"))
        view.open(message: "hi")
        settle()
        let errors = spy.calls.compactMap { call -> String? in if case .error(let e) = call { return e } else { return nil } }
        XCTAssertFalse(errors.contains { $0.lowercased().contains("cancel") || $0.contains("-999") }, "\(errors)")
        XCTAssertEqual(view.pendingOpen as? String, "hi")
    }

    func testSendMessageBeforeInitializeDoesNotReportError() {
        // webView exists from init; evaluateJavaScript on the empty page succeeds.
        let done = expectation(description: "settle")
        view.sendMessage(event: "x")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { done.fulfill() }
        wait(for: [done], timeout: 5)
        XCTAssertEqual(spy.calls, [])
    }

    // MARK: aligned with android/rn (limechat handler, event ?? type, string bodies)

    func testLimechatHandlerCloseWidgetWithWebPayloadRequestsClose() {
        post(["event": "close-widget", "type": "close-widget", "timestamp": 1], name: "limechat")
        XCTAssertEqual(spy.calls, [.requestClose])
    }

    func testTypeOnlyCloseWidgetRequestsClose() {
        post(["type": "close-widget"], name: "limechat")
        XCTAssertEqual(spy.calls, [.requestClose])
    }

    func testEventWinsOverType() {
        post(["event": "close-widget", "type": "other"])
        post(["event": "other", "type": "close-widget"])
        XCTAssertEqual(spy.calls, [.requestClose, .message(["event": "other", "type": "close-widget"])])
    }

    func testNonStringEventFallsBackToType() {
        post(["event": 1, "type": "close-widget"])
        XCTAssertEqual(spy.calls, [.requestClose])
    }

    func testUnreadCountStillWorksOnLimechatHandler() {
        post(["event": "unread_count", "count": 2], name: "limechat")
        XCTAssertEqual(spy.calls, [.unread(2)])
    }

    func testRealJSPostToLimechatLikeWebViewHelperReachesDelegate() {
        loadPage("<html><body></body></html>", into: view, spy: spy)
        let got = expectation(description: "close")
        spy.onCall = { if $0 == .requestClose { got.fulfill() } }
        // same shape as webViewHelper.js sendToIOS: {event, type, timestamp, ...data}
        _ = evalJS("window.webkit.messageHandlers.limechat.postMessage({event: 'close-widget', type: 'close-widget', timestamp: Date.now()}); 1",
                   in: view.testWebView)
        wait(for: [got], timeout: 10)
        XCTAssertEqual(spy.calls, [.didLoad, .requestClose])
    }

}
