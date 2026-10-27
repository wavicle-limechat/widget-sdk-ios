import UIKit
import WebKit

/// Main widget view that renders the Limechat widget in a WebView
public class LimechatWidgetView: UIView {
    
    // MARK: - Properties
    
    private var webView: WKWebView!
    var configuration: WidgetConfiguration?
    var instanceId = ConversationTokenStore.defaultInstanceId
    var cwConversation: String?
    
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
}
