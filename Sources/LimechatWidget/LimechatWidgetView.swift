import UIKit
import WebKit

/// Main widget view that renders the Limechat widget in a WebView
public class LimechatWidgetView: UIView {
    
    // MARK: - Properties
    
    private var webView: WKWebView!
    private var configuration: WidgetConfiguration?
    private var instanceId = ConversationTokenStore.defaultInstanceId
    private var cwConversation: String?
    
    /// Script message handler names. the web posts to `limechat`; `limechatNative` is kept.
    static let messageHandlerNames = ["limechat", "limechatNative"]
    static let messagePrefix = "limechat-widget:"
    
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
    
    deinit {
        let contentController = webView?.configuration.userContentController
        for name in LimechatWidgetView.messageHandlerNames {
            contentController?.removeScriptMessageHandler(forName: name)
        }
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        backgroundColor = .systemBackground
        setupWebView()
    }
    
    private func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        
        let contentController = WKUserContentController()
        let handler = WeakScriptMessageHandler(target: self)
        for name in LimechatWidgetView.messageHandlerNames {
            contentController.add(handler, name: name)
        }
        webConfiguration.userContentController = contentController
        
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        webView = WKWebView(frame: bounds, configuration: webConfiguration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
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
        
        // same as android: instanceId or "default"; external token wins over the stored one
        if let id = configuration.instanceId, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            instanceId = id
        } else {
            instanceId = ConversationTokenStore.defaultInstanceId
        }
        if let token = configuration.conversationToken {
            cwConversation = token
        } else {
            cwConversation = ConversationTokenStore.load(instanceId: instanceId)
        }
        
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
              let url = configuration.widgetURL(cwConversation: cwConversation) else {
            let error = WidgetError.configurationError("Invalid configuration or URL")
            delegate?.widgetDidReceiveError(error)
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func handleConversationTokenUpdate(_ token: String?) {
        guard let token = token, !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        if let onConversationTokenChange = configuration?.onConversationTokenChange {
            // external token management: the host persists the token
            onConversationTokenChange(token)
        } else {
            // internal token management: persist under instanceId
            cwConversation = token
            ConversationTokenStore.save(token, instanceId: instanceId)
        }
        
        delegate?.widgetDidChangeConversationToken(token)
    }
    
    /// Same as android `MessageHandler`: a dictionary, or a json object string with an optional `limechat-widget:` prefix.
    static func parseMessageBody(_ body: Any) -> [String: Any]? {
        if let dict = body as? [String: Any] {
            return dict
        }
        guard var string = body as? String else { return nil }
        if string.hasPrefix(messagePrefix) {
            string.removeFirst(messagePrefix.count)
        }
        guard let data = string.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let dict = json as? [String: Any] else {
            return nil
        }
        return dict
    }
    
    /// Scheme + host + port must equal the configured baseURL (scheme/host case-insensitive, default ports normalised).
    func isWidgetHostURL(_ url: URL) -> Bool {
        guard let base = URL(string: configuration?.baseURL ?? "https://app.limechat.ai"),
              let scheme = base.scheme, let host = base.host,
              url.scheme?.lowercased() == scheme.lowercased(),
              url.host?.lowercased() == host.lowercased() else {
            return false
        }
        return LimechatWidgetView.port(of: url) == LimechatWidgetView.port(of: base)
    }
    
    private static func port(of url: URL) -> Int? {
        if let port = url.port { return port }
        switch url.scheme?.lowercased() {
        case "https": return 443
        case "http": return 80
        default: return nil
        }
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
        
        if url.scheme == "limechat" && url.host == "close" {
            delegate?.widgetDidRequestClose()
            decisionHandler(.cancel)
            return
        }
        
        if isWidgetHostURL(url) {
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
        guard LimechatWidgetView.messageHandlerNames.contains(message.name),
              let body = LimechatWidgetView.parseMessageBody(message.body) else {
            return
        }
        
        if let event = (body["event"] as? String) ?? (body["type"] as? String) {
            switch event {
            case "close", "close-widget":
                delegate?.widgetDidRequestClose()
            case "set-cw-conversation":
                handleConversationTokenUpdate(body["cw_conversation"] as? String)
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