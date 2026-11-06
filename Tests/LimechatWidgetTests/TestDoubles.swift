import XCTest
import UIKit
import WebKit
@testable import LimechatWidget

/// Records every LimechatWidgetDelegate call in order.
final class SpyDelegate: LimechatWidgetDelegate {
    enum Call: Equatable {
        case didLoad
        case requestClose
        case error(String)
        case message(NSDictionary)
        case unread(Int)
        case token(String)
    }

    private(set) var calls: [Call] = []
    var onCall: ((Call) -> Void)?

    private func record(_ call: Call) {
        calls.append(call)
        onCall?(call)
    }

    func widgetDidLoad() { record(.didLoad) }
    func widgetDidRequestClose() { record(.requestClose) }
    func widgetDidReceiveError(_ error: WidgetError) { record(.error(error.errorDescription ?? "")) }
    func widgetDidReceiveMessage(_ message: [String: Any]) { record(.message(message as NSDictionary)) }
    func widgetDidReceiveUnreadCount(_ count: Int) { record(.unread(count)) }
    func widgetDidChangeConversationToken(_ token: String) { record(.token(token)) }
}

/// Implements only the methods without a default, to prove the rest stay optional.
final class MinimalDelegate: LimechatWidgetDelegate {
    func widgetDidLoad() {}
    func widgetDidRequestClose() {}
    func widgetDidReceiveError(_ error: WidgetError) {}
    func widgetDidReceiveMessage(_ message: [String: Any]) {}
}

/// Points ConversationTokenStore at a throwaway UserDefaults suite and an empty cache.
final class TokenStoreSandbox {
    let suiteName = "limechat-tests-\(UUID().uuidString)"
    let defaults: UserDefaults
    private let originalDefaults = ConversationTokenStore.defaults

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
        ConversationTokenStore.defaults = defaults
        ConversationTokenStore.memoryCache = [:]
    }

    func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        ConversationTokenStore.defaults = originalDefaults
        ConversationTokenStore.memoryCache = [:]
    }
}

/// WKScriptMessage with a controllable name/body (WebKit never lets us build a real one).
final class FakeScriptMessage: WKScriptMessage {
    private let fakeName: String
    private let fakeBody: Any

    init(name: String, body: Any) {
        self.fakeName = name
        self.fakeBody = body
        super.init()
    }

    override var name: String { fakeName }
    override var body: Any { fakeBody }
}

/// WKNavigationAction with a controllable request/type.
final class FakeNavigationAction: WKNavigationAction {
    private let fakeRequest: URLRequest
    private let fakeType: WKNavigationType

    init(url: URL?, type: WKNavigationType = .other) {
        var request = URLRequest(url: URL(string: "https://placeholder.invalid")!)
        request.url = url
        self.fakeRequest = request
        self.fakeType = type
        super.init()
    }

    override var request: URLRequest { fakeRequest }
    override var navigationType: WKNavigationType { fakeType }
    override var targetFrame: WKFrameInfo? { nil }
}

/// WKNavigationResponse with a controllable response/main frame flag.
final class FakeNavigationResponse: WKNavigationResponse {
    private let fakeResponse: URLResponse
    private let fakeMainFrame: Bool

    init(statusCode: Int, isMainFrame: Bool = true) {
        self.fakeResponse = HTTPURLResponse(url: URL(string: "https://app.limechat.ai/widget")!, statusCode: statusCode,
                                            httpVersion: nil, headerFields: nil)!
        self.fakeMainFrame = isMainFrame
        super.init()
    }

    override var response: URLResponse { fakeResponse }
    override var isForMainFrame: Bool { fakeMainFrame }
}

extension LimechatWidgetView {
    /// The private WKWebView, found through the view hierarchy (no prod change needed).
    var testWebView: WKWebView {
        subviews.compactMap { $0 as? WKWebView }.first!
    }
}

extension UIView {
    func allSubviews<T: UIView>(of type: T.Type) -> [T] {
        subviews.compactMap { $0 as? T } + subviews.flatMap { $0.allSubviews(of: type) }
    }
}

extension XCTestCase {
    /// Runs decidePolicyFor on the view and returns the synchronous decision.
    func decide(_ view: LimechatWidgetView, url: URL?, type: WKNavigationType = .other) -> WKNavigationActionPolicy? {
        var decision: WKNavigationActionPolicy?
        view.webView(view.testWebView, decidePolicyFor: FakeNavigationAction(url: url, type: type)) { decision = $0 }
        return decision
    }

    /// Loads HTML into the widget's real webview at an allowed origin and waits for widgetDidLoad (fired at ready).
    func loadPage(_ html: String, into view: LimechatWidgetView, spy: SpyDelegate,
                  baseURL: String = "https://app.limechat.ai/", file: StaticString = #filePath, line: UInt = #line) {
        let loaded = expectation(description: "widgetDidLoad")
        spy.onCall = { if $0 == .didLoad { loaded.fulfill() } }
        // the widget posts set-cw-conversation once it mounted; that is the ready signal
        let readyScript = "<script>window.addEventListener('load',function(){webkit.messageHandlers.limechat.postMessage({event:'set-cw-conversation'})})</script>"
        view.testWebView.loadHTMLString(html + readyScript, baseURL: URL(string: baseURL))
        wait(for: [loaded], timeout: 60) // first load cold-starts the WebContent process
        spy.onCall = nil
    }

    /// Runs decidePolicyFor navigationResponse on the view and returns the synchronous decision.
    func decide(_ view: LimechatWidgetView, statusCode: Int, isMainFrame: Bool = true) -> WKNavigationResponsePolicy? {
        var decision: WKNavigationResponsePolicy?
        let response = FakeNavigationResponse(statusCode: statusCode, isMainFrame: isMainFrame)
        _ = Unmanaged.passRetained(response) // WKNavigationResponse.dealloc crashes on a fake, so it is never freed
        view.webView(view.testWebView, decidePolicyFor: response) { decision = $0 }
        return decision
    }

    func evalJS(_ script: String, in webView: WKWebView) -> Any? {
        let done = expectation(description: "eval")
        var out: Any?
        webView.evaluateJavaScript(script) { result, _ in out = result; done.fulfill() }
        wait(for: [done], timeout: 10)
        return out
    }
}
