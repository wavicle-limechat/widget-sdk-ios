import XCTest
import WebKit
@testable import LimechatWidget

/// setMessageAttributes: buffer, flush at ready, order against a held open message.
final class MessageAttributesTests: XCTestCase {

    private var view: LimechatWidgetView!
    private var spy: SpyDelegate!

    override func setUp() {
        super.setUp()
        view = LimechatWidgetView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        spy = SpyDelegate()
        view.delegate = spy
        view.configuration = WidgetConfiguration(websiteToken: "t")
    }

    override func tearDown() {
        view = nil
        spy = nil
        super.tearDown()
    }

    /// Page echoes every window `message` event back over limechat as {event:'echo', data}.
    private let echoPage = """
    <html><body><script>
    window.addEventListener('message', function (e) {
      window.webkit.messageHandlers.limechat.postMessage({event: 'echo', data: e.data});
    });
    </script></body></html>
    """

    private func sent() -> [NSDictionary] {
        spy.calls.compactMap { call -> NSDictionary? in
            guard case .message(let m) = call, m["event"] as? String == "echo",
                  let text = m["data"] as? String, text.hasPrefix("chatwoot-widget:") else { return nil }
            return try? JSONSerialization.jsonObject(with: Data(text.dropFirst("chatwoot-widget:".count).utf8)) as? NSDictionary
        }
    }

    private func waitForSent(_ count: Int) {
        let deadline = Date().addingTimeInterval(10)
        while sent().count < count && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
    }

    private func settle() {
        let done = expectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { done.fulfill() }
        wait(for: [done], timeout: 5)
    }

    func testEmptyAndNonJSONReturnFalseAndLeaveTheBufferAlone() {
        XCTAssertTrue(view.setMessageAttributes(["a": 1]))
        XCTAssertFalse(view.setMessageAttributes([:]))
        XCTAssertFalse(view.setMessageAttributes(["when": Date()]))
        XCTAssertFalse(view.setMessageAttributes(["nan": Double.nan]))
        XCTAssertEqual(view.pendingMessageAttributes as NSDictionary, ["a": 1])
        XCTAssertEqual(spy.calls, [])
    }

    func testAttributesAreHeldBeforeReady() {
        XCTAssertTrue(view.setMessageAttributes(["a": 1]))
        XCTAssertEqual(view.pendingMessageAttributes as NSDictionary, ["a": 1])
        settle()
        XCTAssertEqual(sent().count, 0)
    }

    func testHeldAttributesAreMergedAndSentOnceAtReady() {
        view.setMessageAttributes(["a": 1, "b": 1])
        view.setMessageAttributes(["b": 2, "c": 3])
        loadPage(echoPage, into: view, spy: spy)
        waitForSent(1)
        settle()
        XCTAssertEqual(sent(), [["event": "set-message-attributes", "attributes": ["a": 1, "b": 2, "c": 3]]])
        XCTAssertTrue(view.pendingMessageAttributes.isEmpty)
    }

    func testAttributesAreSentBeforeAHeldOpenMessage() {
        view.pendingOpen = "hi"
        view.setMessageAttributes(["a": 1])
        loadPage(echoPage, into: view, spy: spy)
        waitForSent(2)
        XCTAssertEqual(sent().map { $0["event"] as? String }, ["set-message-attributes", "open-with-message"])
    }

    func testAttributesAreSentAtOnceAfterReady() {
        loadPage(echoPage, into: view, spy: spy)
        XCTAssertTrue(view.setMessageAttributes(["a": 1]))
        waitForSent(1)
        XCTAssertEqual(sent(), [["event": "set-message-attributes", "attributes": ["a": 1]]])
        XCTAssertTrue(view.pendingMessageAttributes.isEmpty)
    }

    func testFlushedAttributesAreNotResentOnANewCommit() {
        view.setMessageAttributes(["a": 1])
        loadPage(echoPage, into: view, spy: spy)
        waitForSent(1)
        loadPage(echoPage, into: view, spy: spy)
        settle()
        XCTAssertEqual(sent().count, 1)
    }

    func testUnflushedAttributesSurviveReload() {
        view.initialize(with: WidgetConfiguration(websiteToken: "t", baseURL: "http://localhost:1"))
        view.setMessageAttributes(["a": 1])
        view.reload()
        XCTAssertEqual(view.pendingMessageAttributes as NSDictionary, ["a": 1])
    }

    func testReInitializeClearsAttributes() {
        let config = WidgetConfiguration(websiteToken: "t", baseURL: "http://localhost:1")
        view.initialize(with: config)
        view.setMessageAttributes(["a": 1])
        view.initialize(with: config)
        XCTAssertTrue(view.pendingMessageAttributes.isEmpty)
    }

    func testAttributesSetBeforeTheFirstInitializeSurvive() {
        view.configuration = nil
        view.setMessageAttributes(["a": 1])
        view.initialize(with: WidgetConfiguration(websiteToken: "t", baseURL: "http://localhost:1"))
        XCTAssertEqual(view.pendingMessageAttributes as NSDictionary, ["a": 1])
    }

    func testSpecialCharsSurviveTheRoundTrip() {
        let tricky = "quote\" apos' </script> \\ 👋 \u{2028}"
        view.setMessageAttributes(["s": tricky])
        loadPage(echoPage, into: view, spy: spy)
        waitForSent(1)
        XCTAssertEqual(sent(), [["event": "set-message-attributes", "attributes": ["s": tricky]]])
    }
}
