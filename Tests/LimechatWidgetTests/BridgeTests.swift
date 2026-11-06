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

    private func post(_ body: Any, name: String = "limechatNative") {
        view.userContentController(view.testWebView.configuration.userContentController,
                                   didReceive: FakeScriptMessage(name: name, body: body))
    }

    // MARK: handler parsing (direct)

    func testCloseEventRequestsClose() {
        post(["event": "close"])
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
        post(["type": "close"])
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

    func testJSONStringBodyAndPrefixedStringBodyAreParsed_invalidStringIsIgnored() {
        post(#"{"event":"close"}"#)
        post(#"limechat-widget:{"event":"close"}"#)
        post("not json")
        XCTAssertEqual(spy.calls, [.requestClose, .requestClose])
    }

    func testNonDictionaryBodiesAreIgnored() {
        post([1, 2, 3])
        post(NSNumber(value: 1))
        post(NSNull())
        XCTAssertEqual(spy.calls, [])
    }

    func testListensOnLimechatAndLimechatNative_otherNamesAreIgnored() {
        post(["event": "close"], name: "limechat")
        post(["event": "close"], name: "LimechatNative")
        post(["event": "close"], name: "limechatnative")
        XCTAssertEqual(spy.calls, [.requestClose])
    }

    func testNoDelegateDoesNotCrash() {
        view.delegate = nil
        post(["event": "close"])
        post(["event": "x"])
    }

    // MARK: handler registration (real WKWebView + JS)

    func testRegistersLimechatAndLimechatNativeHandlers() {
        loadPage("<html><body></body></html>", into: view, spy: spy)
        let web = view.testWebView
        XCTAssertEqual(evalJS("typeof window.webkit.messageHandlers.limechatNative", in: web) as? String, "object")
        XCTAssertEqual(evalJS("typeof window.webkit.messageHandlers.limechat", in: web) as? String, "object")
    }

    func testRealJSPostToLimechatNativeReachesDelegate() {
        loadPage("<html><body></body></html>", into: view, spy: spy)
        let got = expectation(description: "close")
        spy.onCall = { if $0 == .requestClose { got.fulfill() } }
        _ = evalJS("window.webkit.messageHandlers.limechatNative.postMessage({event: 'close'}); 1", in: view.testWebView)
        wait(for: [got], timeout: 10)
        XCTAssertEqual(spy.calls, [.didLoad, .requestClose])
    }

    func testRealJSPostOfJSONStringIsParsed() {
        loadPage("<html><body></body></html>", into: view, spy: spy)
        // json string then a sentinel object; both arrive in order.
        let got = expectation(description: "sentinel")
        spy.onCall = { if case .message = $0 { got.fulfill() } }
        _ = evalJS(#"""
            window.webkit.messageHandlers.limechatNative.postMessage(JSON.stringify({event: 'close'}));
            window.webkit.messageHandlers.limechatNative.postMessage({event: 'sentinel'}); 1
            """#, in: view.testWebView)
        wait(for: [got], timeout: 10)
        XCTAssertEqual(spy.calls, [.didLoad, .requestClose, .message(["event": "sentinel"])])
    }

    // MARK: sendMessage (native -> js)

    /// Page echoes every window `message` event back over limechatNative as {event:'echo', data, isString}.
    private let echoPage = """
    <html><body><script>
    window.addEventListener('message', function (e) {
      window.webkit.messageHandlers.limechatNative.postMessage({event: 'echo', data: e.data, isString: typeof e.data === 'string'});
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

    func testUnreadCountStillWorksOnLimechatHandlerAndFromJSONString() {
        post(["event": "unread_count", "count": 2], name: "limechat")
        post(#"{"event":"unread_count","count":4}"#)
        XCTAssertEqual(spy.calls, [.unread(2), .unread(4)])
    }

    func testPrefixedStringWithUnknownEventIsAMessage() {
        post(#"limechat-widget:{"event":"x","n":1}"#, name: "limechat")
        XCTAssertEqual(spy.calls, [.message(["event": "x", "n": 1])])
    }

    func testInvalidStringBodiesAreIgnored() {
        post("limechat-widget:not json")
        post("[1,2]")
        post(#""just a string""#)
        post("")
        post(#"limechat-widget:"#)
        XCTAssertEqual(spy.calls, [])
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

    func testRealJSPrefixedStringPostIsParsed() {
        loadPage("<html><body></body></html>", into: view, spy: spy)
        let got = expectation(description: "close")
        spy.onCall = { if $0 == .requestClose { got.fulfill() } }
        _ = evalJS("window.webkit.messageHandlers.limechat.postMessage('limechat-widget:' + JSON.stringify({type: 'close-widget'})); 1",
                   in: view.testWebView)
        wait(for: [got], timeout: 10)
        XCTAssertEqual(spy.calls, [.didLoad, .requestClose])
    }
}
