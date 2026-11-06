import Foundation

/// Error types that can occur in the widget
public enum WidgetError: LocalizedError {
    case configurationError(String)
    case webViewError(String)
    
    public var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        case .webViewError(let message):
            return "WebView Error: \(message)"
        }
    }
}