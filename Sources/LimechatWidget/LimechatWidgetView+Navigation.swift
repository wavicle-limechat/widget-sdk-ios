import UIKit
import WebKit

extension LimechatWidgetView {
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
    
    static func port(of url: URL) -> Int? {
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
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.isForMainFrame,
           let response = navigationResponse.response as? HTTPURLResponse,
           response.statusCode >= 400 {
            delegate?.widgetDidReceiveError(.webViewError("HTTP error: \(response.statusCode)"))
        }
        decisionHandler(.allow)
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        pageStarted = true
        widgetReady = false
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        pageStarted = false
        widgetReady = false
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
