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
    public func initialize(with configuration: WidgetConfiguration, initialMessage: String? = nil, initialMessageData: [String: Any]? = nil) {
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
        
        installUserScript()
        loadWidget(openMessage: initialMessage, openPayload: initialMessageData)
    }
    
    /// Send a message to the widget
    public func sendMessage(event: String, data: [String: Any] = [:]) {
        var message = data
        message["event"] = event
        
        guard JSONSerialization.isValidJSONObject(message),
              let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            let error = WidgetError.webViewError("Failed to serialize message")
            delegate?.widgetDidReceiveError(error)
            return
        }
        
        let script = "window.postMessage('chatwoot-widget:' + JSON.stringify(\(jsonString)), '*');"
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                let widgetError = WidgetError.webViewError("Failed to send message: \(error.localizedDescription)")
                self.delegate?.widgetDidReceiveError(widgetError)
            }
        }
    }
    
    /// Reload the widget and open it with a message
    public func open(message: String) {
        guard configuration != nil else { return }
        loadWidget(openMessage: message)
    }
    
    /// Reload the widget and open it with a `{content, submitted_values}` payload
    public func open(messageData: [String: Any]) {
        guard configuration != nil else { return }
        guard JSONSerialization.isValidJSONObject(messageData) else {
            delegate?.widgetDidReceiveError(.webViewError("Failed to serialize message"))
            return
        }
        loadWidget(openPayload: messageData)
    }
    
    /// Reload the widget
    public func reload() {
        loadWidget()
    }
    
    // MARK: - Private Methods
    
    private func installUserScript() {
        let controller = webView.configuration.userContentController
        controller.removeAllUserScripts()
        guard let user = configuration?.user, !user.dictionary.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: user.dictionary),
              let json = String(data: data, encoding: .utf8) else { return }
        let source = "window.chatwootWebChannel = window.chatwootWebChannel || {}; window.chatwootWebChannel.rnUser = \(json);"
        controller.addUserScript(WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
    }
    
    private func loadWidget(openMessage: String? = nil, openPayload: [String: Any]? = nil) {
        guard let configuration = configuration,
              let url = configuration.widgetURL(cwConversation: cwConversation, openMessage: openMessage, openPayload: openPayload) else {
            let error = WidgetError.configurationError("Invalid configuration or URL")
            delegate?.widgetDidReceiveError(error)
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
