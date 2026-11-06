import XCTest
import UIKit
import WebKit
@testable import LimechatWidget

/// Pins the view-controller relay and that the widget view is released (no script-handler retain cycle).
final class LifecycleTests: XCTestCase {

    func testWidgetViewAndWebViewAreReleased() {
        weak var weakView: LimechatWidgetView?
        weak var weakWeb: WKWebView?
        autoreleasepool {
            let view = LimechatWidgetView(frame: .zero)
            weakView = view
            weakWeb = view.testWebView
        }
        // the content controller holds a weak proxy, not the view
        XCTAssertNil(weakView)
        waitUntilReleased { weakWeb == nil }
        XCTAssertNil(weakWeb)
    }

    /// WebKit drops its last internal reference to a WKWebView on a later run loop turn.
    private func waitUntilReleased(timeout: TimeInterval = 5, _ released: () -> Bool) {
        let deadline = Date().addingTimeInterval(timeout)
        while !released() && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
    }

    func testControlPlainUIViewIsReleased() {
        weak var weakView: UIView?
        autoreleasepool {
            let v = UIView()
            weakView = v
        }
        XCTAssertNil(weakView)
    }

    func testViewControllerAndItsWidgetViewAreReleased() {
        weak var weakVC: LimechatWidgetViewController?
        weak var weakWidget: LimechatWidgetView?
        weak var weakWeb: WKWebView?
        autoreleasepool {
            let vc = LimechatWidgetViewController(configuration: WidgetConfiguration(websiteToken: "tok"))
            vc.loadViewIfNeeded()
            weakVC = vc
            weakWidget = vc.view.allSubviews(of: LimechatWidgetView.self).first
            weakWeb = weakWidget?.testWebView
        }
        XCTAssertNil(weakVC)
        XCTAssertNil(weakWidget)
        waitUntilReleased { weakWeb == nil }
        XCTAssertNil(weakWeb)
    }

    // MARK: LimechatWidgetViewController

    func testViewControllerPresentationSettings() {
        let vc = LimechatWidgetViewController(configuration: WidgetConfiguration(websiteToken: "tok"))
        XCTAssertEqual(vc.modalPresentationStyle, .fullScreen)
        XCTAssertEqual(vc.modalTransitionStyle, .coverVertical)
        XCTAssertTrue(vc.prefersStatusBarHidden)
    }

    func testViewControllerEmbedsWidgetViewAndBecomesItsDelegate() {
        let vc = LimechatWidgetViewController(configuration: WidgetConfiguration(websiteToken: "tok"))
        vc.loadViewIfNeeded()
        let widget = vc.view.allSubviews(of: LimechatWidgetView.self).first
        XCTAssertNotNil(widget)
        XCTAssertTrue(widget?.delegate === vc)
    }

    func testViewControllerRelaysAllDelegateCalls() {
        let vc = LimechatWidgetViewController(configuration: WidgetConfiguration(websiteToken: "tok"))
        let spy = SpyDelegate()
        vc.widgetDelegate = spy
        vc.widgetDidLoad()
        vc.widgetDidReceiveError(.webViewError("e"))
        vc.widgetDidReceiveMessage(["a": 1])
        vc.widgetDidReceiveUnreadCount(2)
        vc.widgetDidRequestClose() // also calls dismiss; harmless when not presented
        XCTAssertEqual(spy.calls, [.didLoad, .error("WebView Error: e"), .message(["a": 1]), .unread(2), .requestClose])
    }

    func testViewControllerWithEmptyTokenReportsErrorOnLoad() {
        let vc = LimechatWidgetViewController(configuration: WidgetConfiguration(websiteToken: ""))
        let spy = SpyDelegate()
        vc.widgetDelegate = spy
        vc.loadViewIfNeeded()
        XCTAssertEqual(spy.calls, [.error("Configuration Error: Invalid configuration or URL")])
    }

    func testScriptMessageThroughViewControllerReachesHost() {
        let vc = LimechatWidgetViewController(configuration: WidgetConfiguration(websiteToken: "tok"))
        let spy = SpyDelegate()
        vc.widgetDelegate = spy
        vc.loadViewIfNeeded()
        let widget = vc.view.allSubviews(of: LimechatWidgetView.self).first!
        widget.userContentController(widget.testWebView.configuration.userContentController,
                                     didReceive: FakeScriptMessage(name: "limechat", body: ["event": "unread_count", "count": 7]))
        XCTAssertEqual(spy.calls, [.unread(7)])
    }
}
