import UIKit
import WebKit
import os.log

/// Delegate protocol for widget events
public protocol LimechatWidgetDelegate: AnyObject {
    func widgetDidLoad()
    func widgetDidRequestClose()
    func widgetDidReceiveError(_ error: WidgetError)
    func widgetDidReceiveMessage(_ message: [String: Any])
    func widgetDidReceiveUnreadCount(_ count: Int)
}

/// Widget state enumeration
public enum WidgetState {
    case idle
    case loading
    case loaded
    case error(WidgetError)
}

/// Main widget view that renders the Limechat widget in a WebView
public class LimechatWidgetView: UIView {
    
    // MARK: - Properties
    
    private var webView: WKWebView!
    private var configuration: WidgetConfiguration?
    private var state: WidgetState = .idle {
        didSet {
            DispatchQueue.main.async {
                self.updateUIForState()
            }
        }
    }
    private var loadingIndicator: UIActivityIndicatorView!
    private var errorView: UIView?
    private let logger = OSLog(subsystem: "ai.limechat.widget", category: "LimechatWidgetView")
    private var retryCount = 0
    private let maxRetries = 3
    
    public weak var delegate: LimechatWidgetDelegate?
    
    /// Current widget state
    public var currentState: WidgetState {
        return state
    }
    
    /// Whether the widget is currently loaded
    public var isLoaded: Bool {
        if case .loaded = state {
            return true
        }
        return false
    }
    
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
        setupLoadingIndicator()
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
        
        // Security settings
        if #available(iOS 14.0, *) {
            webConfiguration.limitsNavigationsToAppBoundDomains = true
        }
        
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
    
    private func setupLoadingIndicator() {
        if #available(iOS 13.0, *) {
            loadingIndicator = UIActivityIndicatorView(style: .large)
        } else {
            loadingIndicator = UIActivityIndicatorView(style: .whiteLarge)
        }
        
        loadingIndicator.hidesWhenStopped = true
        addSubview(loadingIndicator)
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func updateUIForState() {
        switch state {
        case .idle:
            loadingIndicator.stopAnimating()
            hideErrorView()
            webView.isHidden = false
            
        case .loading:
            loadingIndicator.startAnimating()
            hideErrorView()
            webView.isHidden = false
            
        case .loaded:
            loadingIndicator.stopAnimating()
            hideErrorView()
            webView.isHidden = false
            
        case .error(let error):
            loadingIndicator.stopAnimating()
            showErrorView(error)
            webView.isHidden = true
        }
    }
    
    // MARK: - Public Methods
    
    /// Initialize the widget with configuration
    public func initialize(with configuration: WidgetConfiguration) {
        do {
            try configuration.validate()
            self.configuration = configuration
            state = .loading
            loadWidget()
            
            if configuration.enableDebugLogs {
                os_log("Widget initialized with configuration", log: logger, type: .info)
            }
        } catch let error as WidgetError {
            state = .error(error)
            delegate?.widgetDidReceiveError(error)
        } catch {
            let widgetError = WidgetError.configurationError("Invalid configuration: \(error.localizedDescription)")
            state = .error(widgetError)
            delegate?.widgetDidReceiveError(widgetError)
        }
    }
    
    /// Send a message to the widget
    public func sendMessage(event: String, data: [String: Any] = [:]) {
        guard isLoaded else {
            let error = WidgetError.javascriptError("Cannot send message: widget not loaded")
            delegate?.widgetDidReceiveError(error)
            return
        }
        
        var message = data
        message["event"] = event
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            let error = WidgetError.javascriptError("Failed to serialize message")
            delegate?.widgetDidReceiveError(error)
            return
        }
        
        let script = "window.postMessage('limechat-widget:\(jsonString)', '*');"
        webView.evaluateJavaScript(script) { [weak self] _, error in
            if let error = error {
                let widgetError = WidgetError.javascriptError("Failed to send message: \(error.localizedDescription)")
                self?.delegate?.widgetDidReceiveError(widgetError)
            }
        }
    }
    
    /// Handle navigation back
    @discardableResult
    public func goBack() -> Bool {
        if webView.canGoBack {
            webView.goBack()
            return true
        }
        return false
    }
    
    /// Reload the widget
    public func reload() {
        retryCount = 0
        loadWidget()
    }
    
    /// Clean up resources
    public func destroy() {
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "limechatNative")
        webView.removeFromSuperview()
        webView = nil
        state = .idle
    }
    
    // MARK: - Private Methods
    
    private func loadWidget() {
        guard let configuration = configuration,
              let url = configuration.widgetURL else {
            let error = WidgetError.configurationError("Invalid configuration or URL")
            state = .error(error)
            delegate?.widgetDidReceiveError(error)
            return
        }
        
        state = .loading
        
        var request = URLRequest(url: url)
        request.timeoutInterval = configuration.requestTimeout
        request.setValue("LimechatWidget-iOS/1.0.0", forHTTPHeaderField: "User-Agent")
        
        webView.load(request)
        
        if configuration.enableDebugLogs {
            os_log("Loading widget URL: %@", log: logger, type: .info, url.absoluteString)
        }
    }
    
    private func injectUserData() {
        guard let configuration = configuration else { return }
        
        var scripts: [String] = []
        
        // Set user data
        if let user = configuration.user {
            let userScript = """
                window.LimechatWidget = window.LimechatWidget || {};
                window.LimechatWidget.setUser = function(user) {
                    window.postMessage(JSON.stringify({
                        event: 'set-user',
                        user: user,
                        identifier: user.identifier_hash
                    }), '*');
                };
                window.LimechatWidget.setUser(\(user.dictionary.jsonString ?? "{}"));
            """
            scripts.append(userScript)
        }
        
        // Set locale
        let localeScript = """
            window.postMessage(JSON.stringify({
                event: 'set-locale',
                locale: '\(configuration.locale)'
            }), '*');
        """
        scripts.append(localeScript)
        
        // Set color scheme
        let isDarkMode = configuration.colorScheme == .dark ||
            (configuration.colorScheme == .auto && traitCollection.userInterfaceStyle == .dark)
        let colorSchemeScript = """
            window.postMessage(JSON.stringify({
                event: 'set-color-scheme',
                darkMode: \(isDarkMode)
            }), '*');
        """
        scripts.append(colorSchemeScript)
        
        // Set custom attributes
        if let customAttributes = configuration.customAttributes,
           let jsonString = customAttributes.jsonString {
            let attributesScript = """
                window.postMessage(JSON.stringify({
                    event: 'set-custom-attributes',
                    customAttributes: \(jsonString)
                }), '*');
            """
            scripts.append(attributesScript)
        }
        
        // Execute all scripts
        for script in scripts {
            webView.evaluateJavaScript(script) { [weak self] _, error in
                if let error = error, let config = self?.configuration, config.enableDebugLogs {
                    os_log("Script execution error: %@", log: self?.logger ?? OSLog.default, type: .error, error.localizedDescription)
                }
            }
        }
    }
    
    private func setupMessageListener() {
        let script = """
            window.addEventListener('message', function(e) {
                if (typeof e.data === 'string' && e.data.startsWith('limechat-widget:')) {
                    window.webkit.messageHandlers.limechatNative.postMessage(e.data);
                }
            });
        """
        webView.evaluateJavaScript(script) { [weak self] _, error in
            if let error = error, let config = self?.configuration, config.enableDebugLogs {
                os_log("Message listener setup error: %@", log: self?.logger ?? OSLog.default, type: .error, error.localizedDescription)
            }
        }
    }
    
    private func showErrorView(_ error: WidgetError) {
        hideErrorView()
        
        let errorContainer = UIView()
        errorContainer.backgroundColor = .systemBackground
        
        let iconLabel = UILabel()
        iconLabel.text = "⚠️"
        iconLabel.font = .systemFont(ofSize: 48)
        iconLabel.textAlignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = "Widget Error"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        
        let messageLabel = UILabel()
        messageLabel.text = error.errorDescription
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textAlignment = .center
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        
        let retryButton = UIButton(type: .system)
        retryButton.setTitle("Retry", for: .normal)
        retryButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        
        // Only show retry button for recoverable errors
        retryButton.isHidden = !error.isRecoverable || retryCount >= maxRetries
        
        let stackView = UIStackView(arrangedSubviews: [iconLabel, titleLabel, messageLabel, retryButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        
        errorContainer.addSubview(stackView)
        addSubview(errorContainer)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        errorContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            errorContainer.topAnchor.constraint(equalTo: topAnchor),
            errorContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            errorContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            stackView.centerXAnchor.constraint(equalTo: errorContainer.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: errorContainer.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: errorContainer.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: errorContainer.trailingAnchor, constant: -32)
        ])
        
        errorView = errorContainer
    }
    
    private func hideErrorView() {
        errorView?.removeFromSuperview()
        errorView = nil
    }
    
    @objc private func retryButtonTapped() {
        if retryCount < maxRetries {
            retryCount += 1
            loadWidget()
        }
    }
}

// MARK: - WKNavigationDelegate

extension LimechatWidgetView: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject user data and setup messaging after page loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.injectUserData()
            self?.setupMessageListener()
            self?.state = .loaded
            self?.retryCount = 0
            self?.delegate?.widgetDidLoad()
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let widgetError: WidgetError
        
        if let urlError = error as? URLError {
            widgetError = WidgetError.from(urlError)
        } else {
            widgetError = WidgetError.webViewError(error.localizedDescription)
        }
        
        state = .error(widgetError)
        delegate?.widgetDidReceiveError(widgetError)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let widgetError: WidgetError
        
        if let urlError = error as? URLError {
            widgetError = WidgetError.from(urlError)
        } else {
            widgetError = WidgetError.webViewError(error.localizedDescription)
        }
        
        state = .error(widgetError)
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
        if let baseURL = configuration?.baseURL,
           url.absoluteString.hasPrefix(baseURL) {
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
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        
        if let viewController = self.findViewController() {
            viewController.present(alert, animated: true)
        } else {
            completionHandler()
        }
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        })
        
        if let viewController = self.findViewController() {
            viewController.present(alert, animated: true)
        } else {
            completionHandler(false)
        }
    }
}

// MARK: - WKScriptMessageHandler

extension LimechatWidgetView: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? String,
              messageBody.hasPrefix("limechat-widget:") else {
            return
        }
        
        let jsonString = String(messageBody.dropFirst("limechat-widget:".count))
        
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        if let event = json["event"] as? String {
            switch event {
            case "loaded":
                state = .loaded
                delegate?.widgetDidLoad()
            case "close-widget":
                delegate?.widgetDidRequestClose()
            case "unread-count":
                if let count = json["count"] as? Int {
                    delegate?.widgetDidReceiveUnreadCount(count)
                }
            default:
                delegate?.widgetDidReceiveMessage(json)
            }
        }
    }
}

// MARK: - Helper Extensions

private extension Dictionary where Key == String {
    var jsonString: String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
}

private extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}