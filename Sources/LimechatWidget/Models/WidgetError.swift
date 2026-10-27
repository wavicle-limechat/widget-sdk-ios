import Foundation

/// Error types that can occur in the widget
public enum WidgetError: LocalizedError {
    case configurationError(String)
    case networkError(String)
    case webViewError(String)
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .webViewError(let message):
            return "WebView Error: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
}