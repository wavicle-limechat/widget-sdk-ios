import XCTest
import UIKit
@testable import LimechatWidget

/// Pins LimechatWidgetIcon, addWidgetIcon and LimechatWidget (second launcher) without rendering.
/// presenting the widget on tap is not driven: the spm test runner has no UIApplication/window.
final class LauncherTests: XCTestCase {

    private let config = WidgetConfiguration(websiteToken: "tok")

    private func labels(_ v: UIView) -> [UILabel] { v.allSubviews(of: UILabel.self) }

    // MARK: LimechatWidgetIcon defaults

    func testIconDefaults() {
        let icon = LimechatWidgetIcon()
        XCTAssertEqual(icon.iconSize, 60)
        XCTAssertEqual(icon.cornerRadius, 30)
        XCTAssertEqual(icon.layer.cornerRadius, 30)
        XCTAssertEqual(icon.backgroundColor, .systemBlue)
        XCTAssertEqual(icon.layer.shadowOpacity, 0.2)
        XCTAssertEqual(icon.layer.shadowRadius, 4)
        XCTAssertEqual(icon.layer.shadowOffset, CGSize(width: 0, height: 2))
        XCTAssertEqual(icon.gestureRecognizers?.count, 1)
        XCTAssertTrue(icon.gestureRecognizers?.first is UITapGestureRecognizer)
        let image = icon.allSubviews(of: UIImageView.self).first
        XCTAssertEqual(image?.tintColor, .white)
        XCTAssertEqual(image?.image, UIImage(systemName: "message.fill"))
    }

    func testIconCustomIconAndReset() {
        let icon = LimechatWidgetIcon()
        let custom = UIImage()
        icon.customIcon = custom
        XCTAssertTrue(icon.allSubviews(of: UIImageView.self).first?.image === custom)
        icon.customIcon = nil
        XCTAssertEqual(icon.allSubviews(of: UIImageView.self).first?.image, UIImage(systemName: "message.fill"))
    }

    func testIconCornerRadiusAndTintSetters() {
        let icon = LimechatWidgetIcon()
        icon.cornerRadius = 12
        XCTAssertEqual(icon.layer.cornerRadius, 12)
        icon.tintColor = .red
        XCTAssertEqual(icon.allSubviews(of: UIImageView.self).first?.tintColor, .red)
    }

    // MARK: icon unread label

    func testIconUnreadLabel() {
        let icon = LimechatWidgetIcon()
        XCTAssertTrue(labels(icon).isEmpty)
        icon.setUnreadCount(5)
        XCTAssertEqual(labels(icon).map(\.text), ["5"])
        XCTAssertEqual(labels(icon).first?.backgroundColor, .systemRed)
        icon.setUnreadCount(99)
        XCTAssertEqual(labels(icon).map(\.text), ["99"])
        icon.setUnreadCount(100)
        XCTAssertEqual(labels(icon).map(\.text), ["99+"])
        icon.setUnreadCount(0)
        XCTAssertTrue(labels(icon).isEmpty)
    }

    func testIconNegativeUnreadShowsNoLabel() {
        let icon = LimechatWidgetIcon()
        icon.setUnreadCount(-3)
        XCTAssertTrue(labels(icon).isEmpty)
    }

    // MARK: icon tap

    func testIconTapWithoutInitializeReportsConfigurationError() {
        let icon = LimechatWidgetIcon()
        let spy = SpyDelegate()
        icon.delegate = spy
        icon.perform(NSSelectorFromString("iconTapped"))
        XCTAssertEqual(spy.calls, [.error("Configuration Error: Widget not initialized")])
    }

    func testIconTapWithoutViewControllerReportsConfigurationError() {
        let icon = LimechatWidgetIcon()
        let spy = SpyDelegate()
        icon.delegate = spy
        icon.initialize(with: config)
        icon.perform(NSSelectorFromString("iconTapped"))
        XCTAssertEqual(spy.calls, [.error("Configuration Error: Cannot find view controller")])
    }

    // MARK: addWidgetIcon

    private func constraints(of icon: UIView, in vc: UIViewController) -> [NSLayoutConstraint] {
        (vc.view.constraints + icon.constraints).filter { $0.firstItem === icon }
    }

    private func check(_ position: WidgetIconPosition,
                       vertical: NSLayoutConstraint.Attribute, verticalConstant: CGFloat,
                       horizontal: NSLayoutConstraint.Attribute, horizontalConstant: CGFloat,
                       line: UInt = #line) {
        let vc = UIViewController()
        let spy = SpyDelegate()
        let icon = vc.addWidgetIcon(configuration: config, delegate: spy, position: position)
        XCTAssertTrue(icon.superview === vc.view, line: line)
        XCTAssertFalse(icon.translatesAutoresizingMaskIntoConstraints, line: line)
        XCTAssertTrue(icon.delegate === spy, line: line)

        let cs = constraints(of: icon, in: vc)
        XCTAssertEqual(cs.count, 4, line: line)
        let v = cs.first { $0.firstAttribute == vertical }
        XCTAssertTrue(v?.secondItem === vc.view.safeAreaLayoutGuide, line: line)
        XCTAssertEqual(v?.secondAttribute, vertical, line: line)
        XCTAssertEqual(v?.constant, verticalConstant, line: line)
        let h = cs.first { $0.firstAttribute == horizontal }
        XCTAssertTrue(h?.secondItem === vc.view.safeAreaLayoutGuide, line: line)
        XCTAssertEqual(h?.constant, horizontalConstant, line: line)
        XCTAssertEqual(cs.first { $0.firstAttribute == .width }?.constant, 60, line: line)
        XCTAssertEqual(cs.first { $0.firstAttribute == .height }?.constant, 60, line: line)
        XCTAssertTrue(cs.allSatisfy { $0.isActive && $0.relation == .equal }, line: line)
    }

    func testAddWidgetIconBottomRightIsDefault() {
        let vc = UIViewController()
        let icon = vc.addWidgetIcon(configuration: config)
        let cs = constraints(of: icon, in: vc)
        XCTAssertEqual(cs.first { $0.firstAttribute == .bottom }?.constant, -20)
        XCTAssertEqual(cs.first { $0.firstAttribute == .trailing }?.constant, -20)
    }

    func testAddWidgetIconPositions() {
        check(.bottomRight, vertical: .bottom, verticalConstant: -20, horizontal: .trailing, horizontalConstant: -20)
        check(.bottomLeft, vertical: .bottom, verticalConstant: -20, horizontal: .leading, horizontalConstant: 20)
        check(.topRight, vertical: .top, verticalConstant: 20, horizontal: .trailing, horizontalConstant: -20)
        check(.topLeft, vertical: .top, verticalConstant: 20, horizontal: .leading, horizontalConstant: 20)
    }

    func testAddWidgetIconInitializesIconSoTapReachesPresentStep() {
        // initialized icon in a vc hierarchy: no config error, no find-vc error.
        // we stop before presenting (needs a window), so only assert the guard order via a detached icon.
        let vc = UIViewController()
        let icon = vc.addWidgetIcon(configuration: config, customIcon: UIImage())
        XCTAssertNotNil(icon.allSubviews(of: UIImageView.self).first?.image)
        icon.removeFromSuperview()
        let spy = SpyDelegate()
        icon.delegate = spy
        icon.perform(NSSelectorFromString("iconTapped"))
        XCTAssertEqual(spy.calls, [.error("Configuration Error: Cannot find view controller")])
    }

    func testAddWidgetIconWithCustomIconSkipsTheIconFetch() {
        CountingURLProtocol.count = 0
        URLProtocol.registerClass(CountingURLProtocol.self)
        defer { URLProtocol.unregisterClass(CountingURLProtocol.self) }
        let own = WidgetConfiguration(websiteToken: "t", baseURL: "https://custom-icon-test.invalid")
        _ = UIViewController().addWidgetIcon(configuration: own, customIcon: UIImage())
        RunLoop.main.run(until: Date().addingTimeInterval(1))
        XCTAssertEqual(CountingURLProtocol.count, 0)
    }

    func testPinsCurrentBehaviour_iconSizeChangeAfterAddWidgetIconIsIgnored() {
        let vc = UIViewController()
        let icon = vc.addWidgetIcon(configuration: config)
        icon.iconSize = 100
        let cs = constraints(of: icon, in: vc)
        XCTAssertEqual(cs.first { $0.firstAttribute == .width }?.constant, 60)
        XCTAssertEqual(cs.first { $0.firstAttribute == .height }?.constant, 60)
    }

    func testAddWidgetIconTwiceAddsTwoIcons() {
        let vc = UIViewController()
        _ = vc.addWidgetIcon(configuration: config)
        _ = vc.addWidgetIcon(configuration: config)
        XCTAssertEqual(vc.view.subviews.filter { $0 is LimechatWidgetIcon }.count, 2)
    }

    // MARK: LimechatWidget (second launcher)

    private func badge(_ w: LimechatWidget) -> UIView? {
        w.subviews.first { $0.viewWithTag(999) is UILabel }
    }

    func testLimechatWidgetDefaultModeUsesIconPlusHiddenBadge() {
        let spy = SpyDelegate()
        let w = LimechatWidget(configuration: config, delegate: spy)
        XCTAssertEqual(w.subviews.count, 2)
        let icon = w.subviews.first as? LimechatWidgetIcon
        XCTAssertNotNil(icon)
        XCTAssertTrue(icon?.delegate === spy)
        XCTAssertEqual(w.gestureRecognizers ?? [], [])
        XCTAssertEqual(badge(w)?.isHidden, true)
        XCTAssertEqual(badge(w)?.backgroundColor, .systemRed)
        XCTAssertEqual(badge(w)?.layer.cornerRadius, 10)
    }

    func testLimechatWidgetCustomButtonModeWrapsButtonInTappableContainer() {
        let button = UIView()
        let w = LimechatWidget(configuration: config, customButton: button)
        XCTAssertEqual(w.subviews.count, 2)
        XCTAssertTrue(w.allSubviews(of: LimechatWidgetIcon.self).isEmpty)
        let container = button.superview
        XCTAssertTrue(container?.superview === w)
        XCTAssertEqual(container?.gestureRecognizers?.count, 1)
        XCTAssertNil(button.gestureRecognizers)
        XCTAssertNotNil(badge(w))
    }

    func testLimechatWidgetOpenPresentsTheWidgetWithTheMessage() {
        let host = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        let w = LimechatWidget(configuration: config)
        host.view.addSubview(w)
        w.open(message: "hi")
        let presented = host.presentedViewController as? LimechatWidgetViewController
        XCTAssertNotNil(presented)
        let url = presented?.view.allSubviews(of: LimechatWidgetView.self).first?.testWebView.url
        XCTAssertTrue(url?.absoluteString.contains("lc_open_message=hi") == true, "\(String(describing: url))")
        window.isHidden = true
    }

    func testLimechatWidgetOpenWhileOpenSendsTheMessageToThePresentedWidget() {
        let host = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        let w = LimechatWidget(configuration: config)
        host.view.addSubview(w)
        w.open(message: "first")
        let first = host.presentedViewController
        w.open(message: "second")
        XCTAssertTrue(host.presentedViewController === first)
        let presented = host.presentedViewController as? LimechatWidgetViewController
        let url = presented?.view.allSubviews(of: LimechatWidgetView.self).first?.testWebView.url
        XCTAssertTrue(url?.absoluteString.contains("lc_open_message=second") == true, "\(String(describing: url))")
        window.isHidden = true
    }

    func testLimechatWidgetOpenWhileOpenSendsMessageDataToThePresentedWidget() {
        let host = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        let w = LimechatWidget(configuration: config)
        host.view.addSubview(w)
        w.open(message: "first")
        let first = host.presentedViewController
        w.open(messageData: ["content": "payload"])
        XCTAssertTrue(host.presentedViewController === first)
        let presented = host.presentedViewController as? LimechatWidgetViewController
        let url = presented?.view.allSubviews(of: LimechatWidgetView.self).first?.testWebView.url
        XCTAssertTrue(url?.absoluteString.contains("lc_open_payload") == true, "\(String(describing: url))")
        XCTAssertTrue(url?.absoluteString.contains("payload") == true, "\(String(describing: url))")
        window.isHidden = true
    }

    func testLimechatWidgetOpenWhileAnotherLauncherIsOpenDoesNotSendTheMessageToIt() {
        let host = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        let a = LimechatWidget(configuration: WidgetConfiguration(websiteToken: "tokenA"))
        let b = LimechatWidget(configuration: WidgetConfiguration(websiteToken: "tokenB"))
        host.view.addSubview(a)
        host.view.addSubview(b)
        a.open(message: "for A")
        let first = host.presentedViewController
        b.open(message: "for B")
        b.open(messageData: ["content": "for B"])
        XCTAssertTrue(host.presentedViewController === first)
        let presented = host.presentedViewController as? LimechatWidgetViewController
        let url = presented?.view.allSubviews(of: LimechatWidgetView.self).first?.testWebView.url
        XCTAssertTrue(url?.absoluteString.contains("website_token=tokenA") == true, "\(String(describing: url))")
        XCTAssertFalse(url?.absoluteString.contains("for%20B") == true, "\(String(describing: url))")
        window.isHidden = true
    }

    func testLimechatWidgetOpenWithoutViewControllerIsSilent() {
        let w = LimechatWidget(configuration: config)
        w.open(message: "hi")
        w.open()
    }

    func testLimechatWidgetCustomButtonTapWithoutViewControllerIsSilent() {
        let spy = SpyDelegate()
        let w = LimechatWidget(configuration: config, customButton: UIView(), delegate: spy)
        w.perform(NSSelectorFromString("handleButtonPress"))
        XCTAssertEqual(spy.calls, []) // unlike LimechatWidgetIcon, no error reported
    }

    func testLimechatWidgetBadgeText() {
        let w = LimechatWidget(configuration: config, customButton: UIView())
        let label = badge(w)?.viewWithTag(999) as? UILabel
        w.setUnreadCount(5)
        XCTAssertEqual(badge(w)?.isHidden, false)
        XCTAssertEqual(label?.text, "5")
        w.setUnreadCount(150)
        XCTAssertEqual(label?.text, "99+")
        w.setUnreadCount(0)
        XCTAssertEqual(badge(w)?.isHidden, true)
        XCTAssertEqual(label?.text, "99+") // text is left stale while hidden
    }

    func testDefaultModeShowsOneUnreadBadge() {
        let w = LimechatWidget(configuration: config)
        w.setUnreadCount(3)
        let visible = labels(w).filter { $0.text == "3" }
        XCTAssertEqual(visible.count, 1) // only the LimechatWidget badge
        XCTAssertEqual(badge(w)?.isHidden, false)
        XCTAssertTrue(visible.first?.superview === badge(w))
        let icon = w.subviews.first as? LimechatWidgetIcon
        XCTAssertEqual(icon.map(labels)?.count, 0)
    }

    func testPinsCurrentBehaviour_changingCustomButtonResetsBadgeAndDropsUnreadCount() {
        let w = LimechatWidget(configuration: config, customButton: UIView())
        w.setUnreadCount(4)
        w.customButton = UIView()
        XCTAssertEqual(badge(w)?.isHidden, true)
        XCTAssertNil((badge(w)?.viewWithTag(999) as? UILabel)?.text)
    }

    func testCustomButtonSetToNilSwitchesToDefaultIcon() {
        let w = LimechatWidget(configuration: config, customButton: UIView())
        w.customButton = nil
        XCTAssertTrue(w.subviews.first is LimechatWidgetIcon)
    }

    func testDelegateSetAfterInitIsPassedToIcon() {
        let w = LimechatWidget(configuration: config)
        let spy = SpyDelegate()
        w.delegate = spy
        XCTAssertTrue((w.subviews.first as? LimechatWidgetIcon)?.delegate === spy)
    }

    func testIconStyleWithCGFloatValues() {
        let w = LimechatWidget(configuration: config)
        w.iconStyle = ["size": CGFloat(70), "cornerRadius": CGFloat(8), "backgroundColor": UIColor.green, "tintColor": UIColor.black]
        let icon = w.subviews.first as! LimechatWidgetIcon
        XCTAssertEqual(icon.iconSize, 70)
        XCTAssertEqual(icon.layer.cornerRadius, 8)
        XCTAssertEqual(icon.backgroundColor, .green)
        XCTAssertEqual(icon.tintColor, .black)
    }

    func testPinsCurrentBehaviour_iconStyleIntAndDoubleLiteralsAreIgnored() {
        let w = LimechatWidget(configuration: config)
        w.iconStyle = ["size": 70, "cornerRadius": 8.0]
        let icon = w.subviews.first as! LimechatWidgetIcon
        XCTAssertEqual(icon.iconSize, 60)
        XCTAssertEqual(icon.layer.cornerRadius, 30)
    }

    func testUnreadCountStyle() {
        let w = LimechatWidget(configuration: config)
        w.unreadCountStyle = ["backgroundColor": UIColor.purple, "cornerRadius": CGFloat(4)]
        XCTAssertEqual(badge(w)?.backgroundColor, .purple)
        XCTAssertEqual(badge(w)?.layer.cornerRadius, 4)
    }

    func testContainerStyleIsANoOp() {
        let w = LimechatWidget(configuration: config)
        let before = w.backgroundColor
        w.containerStyle = ["backgroundColor": UIColor.red]
        XCTAssertEqual(w.backgroundColor, before)
    }

    func testSwiftUIWrapperStoresInputs() {
        let spy = SpyDelegate()
        let button = UIView()
        let s = LimechatWidgetSwiftUIView(configuration: config, customButton: button, delegate: spy)
        XCTAssertEqual(s.configuration.websiteToken, "tok")
        XCTAssertTrue(s.customButton === button)
        XCTAssertTrue(s.delegate === spy)
    }
}

final class CountingURLProtocol: URLProtocol {
    static var count = 0
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "custom-icon-test.invalid" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        CountingURLProtocol.count += 1
        client?.urlProtocol(self, didFailWithError: URLError(.cancelled))
    }
    override func stopLoading() {}
}
