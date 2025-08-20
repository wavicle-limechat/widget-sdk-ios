import UIKit
import WebKit

/// Delegate protocol for widget events
public protocol LimechatWidgetDelegate: AnyObject {
    func widgetDidLoad()
    func widgetDidRequestClose()
    func widgetDidReceiveError(_ error: WidgetError)
    func widgetDidReceiveMessage(_ message: [String: Any])
    func widgetDidReceiveUnreadCount(_ count: Int)
}

/// Main widget view that renders the Limechat widget in a WebView
public class LimechatWidgetView: UIView {
    
    // MARK: - Properties
    
    private var webView: WKWebView!
    private var configuration: WidgetConfiguration?
    
    public weak var delegate: LimechatWidgetDelegate?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        backgroundColor = .systemBackground
        setupWebView()
    }
    
    private func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        
        // Enable JavaScript
        webConfiguration.preferences.javaScriptEnabled = true
        
        // Add message handler for communication
        let contentController = WKUserContentController()
        contentController.add(self, name: "limechatNative")
        webConfiguration.userContentController = contentController
        
        // Configure for inline media playback
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        // Create WebView
        webView = WKWebView(frame: bounds, configuration: webConfiguration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Configure WebView settings
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        // Handle safe area for modern devices
        if #available(iOS 11.0, *) {
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    // MARK: - Public Methods
    
    /// Initialize the widget with configuration
    public func initialize(with configuration: WidgetConfiguration) {
        self.configuration = configuration
        loadWidget()
    }
    
    /// Send a message to the widget
    public func sendMessage(event: String, data: [String: Any] = [:]) {
        var message = data
        message["event"] = event
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            let error = WidgetError.webViewError("Failed to serialize message")
            delegate?.widgetDidReceiveError(error)
            return
        }
        
        let script = "window.postMessage(\(jsonString), '*');"
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                let widgetError = WidgetError.webViewError("Failed to send message: \(error.localizedDescription)")
                self.delegate?.widgetDidReceiveError(widgetError)
            }
        }
    }
    
    /// Reload the widget
    public func reload() {
        loadWidget()
    }
    
    // MARK: - Private Methods
    
    private func loadWidget() {
        guard let configuration = configuration,
              let url = configuration.widgetURL else {
            let error = WidgetError.configurationError("Invalid configuration or URL")
            delegate?.widgetDidReceiveError(error)
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

// MARK: - WKNavigationDelegate

extension LimechatWidgetView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.widgetDidLoad()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let widgetError = WidgetError.webViewError("Failed to load widget: \(error.localizedDescription)")
        delegate?.widgetDidReceiveError(widgetError)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let widgetError = WidgetError.webViewError("Failed to load widget: \(error.localizedDescription)")
        delegate?.widgetDidReceiveError(widgetError)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        // Handle special URLs
        if url.scheme == "limechat" && url.host == "close" {
            delegate?.widgetDidRequestClose()
            decisionHandler(.cancel)
            return
        }
        
        // Only allow loading widget URLs
        if url.absoluteString.hasPrefix("https://app.limechat.ai") {
            decisionHandler(.allow)
        } else {
            // Allow external links to open in Safari
            if navigationAction.navigationType == .linkActivated {
                UIApplication.shared.open(url)
            }
            decisionHandler(.cancel)
        }
    }
}

// MARK: - WKUIDelegate

extension LimechatWidgetView: WKUIDelegate {
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Handle new window requests by opening in Safari
        if let url = navigationAction.request.url {
            UIApplication.shared.open(url)
        }
        return nil
    }
}

// MARK: - WKScriptMessageHandler

extension LimechatWidgetView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "limechatNative",
              let body = message.body as? [String: Any] else {
            return
        }
        
        // Handle different message types
        if let event = body["event"] as? String {
            switch event {
            case "close":
                delegate?.widgetDidRequestClose()
            case "unread_count":
                if let count = body["count"] as? Int {
                    delegate?.widgetDidReceiveUnreadCount(count)
                }
            default:
                delegate?.widgetDidReceiveMessage(body)
            }
        } else {
            delegate?.widgetDidReceiveMessage(body)
        }
    }
}