import UIKit
import WebKit

/// Main widget view that renders the Limechat widget in a WebView
public class LimechatWidgetView: UIView {
    
    // MARK: - Properties
    
    private var webView: WKWebView!
    var configuration: WidgetConfiguration?
    var instanceId = ConversationTokenStore.defaultInstanceId
    var cwConversation: String?
    /// true once the current document committed
    var pageStarted = false
    /// true once the widget posted set-cw-conversation on the current document
    var widgetReady = false
    /// one reload is allowed after the web process dies. a ready page resets it
    var processRecoveryUsed = false
    var pendingOpen: Any?
    var pendingMessageAttributes: [String: Any] = [:]
    
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
        if self.configuration != nil { pendingMessageAttributes = [:] }
        self.configuration = configuration
        pendingOpen = nil
        
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
        if let raw = initialMessageData, !raw.isEmpty {
            let data = LimechatWidgetView.withDefaultContent(raw)
            if JSONSerialization.isValidJSONObject(data) {
                pendingOpen = data
            } else {
                delegate?.widgetDidReceiveError(.webViewError("Failed to serialize message"))
            }
        }
        if pendingOpen == nil, let message = initialMessage, !message.isEmpty {
            pendingOpen = message
        }
        loadWidget()
    }
    
    /// Send a message to the widget
    public func sendMessage(event: String, data: [String: Any] = [:]) {
        deliver(event: event, data: data)
    }
    
    /// - Returns: false when the message could not be serialised, nothing was sent
    @discardableResult
    func deliver(event: String, data: [String: Any]) -> Bool {
        var message = data
        message["event"] = event
        
        guard JSONSerialization.isValidJSONObject(message),
              let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            let error = WidgetError.webViewError("Failed to serialize message")
            delegate?.widgetDidReceiveError(error)
            return false
        }
        
        let script = "window.postMessage('chatwoot-widget:' + JSON.stringify(\(jsonString)), '*');"
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                let widgetError = WidgetError.webViewError("Failed to send message: \(error.localizedDescription)")
                self.delegate?.widgetDidReceiveError(widgetError)
            }
        }
        return true
    }
    
    /// Open the widget with a message. Sent now if the widget is ready, otherwise held until it is
    public func open(message: String) {
        guard configuration != nil, !message.isEmpty else { return }
        deliverOpen(message)
    }
    
    /// Open the widget with a `{content, submitted_values}` payload
    public func open(messageData: [String: Any]) {
        guard configuration != nil, !messageData.isEmpty else { return }
        let data = LimechatWidgetView.withDefaultContent(messageData)
        guard JSONSerialization.isValidJSONObject(data) else {
            delegate?.widgetDidReceiveError(.webViewError("Failed to serialize message"))
            return
        }
        deliverOpen(data)
    }
    
    /// Attach custom attributes to the customer's next message. Repeat calls merge, later keys win.
    /// Held until the widget is ready, and sent before a held open message.
    /// - Returns: false for an empty or non-json value
    @discardableResult
    public func setMessageAttributes(_ attributes: [String: Any]) -> Bool {
        guard !attributes.isEmpty, JSONSerialization.isValidJSONObject(attributes) else { return false }
        pendingMessageAttributes.merge(attributes) { _, new in new }
        flushMessageAttributes()
        return true
    }
    
    func flushMessageAttributes() {
        guard widgetReady, !pendingMessageAttributes.isEmpty else { return }
        if deliver(event: "set-message-attributes", data: ["attributes": pendingMessageAttributes]) {
            pendingMessageAttributes = [:]
        }
    }
    
    /// Reload the widget
    public func reload() {
        guard configuration != nil else { return }
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
    
    /// Like the web sdk: no `content` (missing, null or empty) with other keys gets `content: "Hi"`
    static func withDefaultContent(_ data: [String: Any]) -> [String: Any] {
        let content = data["content"]
        let missing = content == nil || content is NSNull || (content as? String)?.isEmpty == true
        guard missing, data.keys.contains(where: { $0 != "content" }) else { return data }
        var copy = data
        copy["content"] = "Hi"
        return copy
    }
    
    private func deliverOpen(_ message: Any) {
        if widgetReady {
            sendMessage(event: "open-with-message", data: ["openMessage": message])
            return
        }
        pendingOpen = message
        if !webView.isLoading { loadWidget() }
    }
    
    func loadWidget() {
        guard let configuration = configuration,
              let url = configuration.widgetURL(cwConversation: cwConversation) else {
            let error = WidgetError.configurationError("Invalid configuration or URL")
            delegate?.widgetDidReceiveError(error)
            return
        }
        
        pageStarted = false
        widgetReady = false
        webView.load(URLRequest(url: url))
    }
}
