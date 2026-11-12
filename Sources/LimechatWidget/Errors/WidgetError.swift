import Foundation

/// Error types that can occur in the widget
public enum WidgetError: LocalizedError {
    case configurationError(String)
    @available(*, deprecated, message: "never produced by the sdk; will be removed in 1.0")
    case networkError(String)
    case webViewError(String)
    @available(*, deprecated, message: "never produced by the sdk; will be removed in 1.0")
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
    
    /// Create error from URLError
    @available(*, deprecated, message: "never produced by the sdk; will be removed in 1.0")
    public static func from(_ urlError: URLError) -> WidgetError {
        switch urlError.code {
        case .timedOut:
            return .networkError("Request timed out")
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkError("No internet connection")
        default:
            return .networkError("Network error: \(urlError.localizedDescription)")
        }
    }
}
