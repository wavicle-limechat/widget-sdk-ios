import Foundation

/// Error types that can occur in the widget
public enum WidgetError: LocalizedError, CustomDebugStringConvertible {
    case configurationError(String)
    case networkError(String, Int? = nil)
    case webViewError(String)
    case javascriptError(String)
    case timeoutError(String)
    case securityError(String)
    case unknownError(String)
    
    /// Error codes for programmatic handling
    public var errorCode: Int {
        switch self {
        case .configurationError:
            return 1001
        case .networkError:
            return 1002
        case .webViewError:
            return 1003
        case .javascriptError:
            return 1004
        case .timeoutError:
            return 1005
        case .securityError:
            return 1006
        case .unknownError:
            return 1999
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        case .networkError(let message, let statusCode):
            let codeText = statusCode.map { " (HTTP \($0))" } ?? ""
            return "Network Error: \(message)\(codeText)"
        case .webViewError(let message):
            return "WebView Error: \(message)"
        case .javascriptError(let message):
            return "JavaScript Error: \(message)"
        case .timeoutError(let message):
            return "Timeout Error: \(message)"
        case .securityError(let message):
            return "Security Error: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
    
    public var debugDescription: String {
        return "WidgetError(code: \(errorCode), description: \(errorDescription ?? "Unknown"))"
    }
    
    /// Recovery suggestions for different error types
    public var recoverySuggestion: String? {
        switch self {
        case .configurationError:
            return "Please check your widget configuration parameters and try again."
        case .networkError:
            return "Please check your internet connection and try again."
        case .webViewError:
            return "Please restart the widget or try again later."
        case .javascriptError:
            return "Please refresh the widget or contact support if the issue persists."
        case .timeoutError:
            return "Request timed out. Please check your internet connection and try again."
        case .securityError:
            return "Security validation failed. Please ensure you're using a valid website token."
        case .unknownError:
            return "An unexpected error occurred. Please try again or contact support."
        }
    }
    
    /// Whether the error is recoverable by retrying
    public var isRecoverable: Bool {
        switch self {
        case .configurationError, .securityError:
            return false
        case .networkError, .webViewError, .javascriptError, .timeoutError, .unknownError:
            return true
        }
    }
    
    /// Create error from URLError
    public static func from(_ urlError: URLError) -> WidgetError {
        switch urlError.code {
        case .timedOut:
            return .timeoutError("Request timed out: \(urlError.localizedDescription)")
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkError("No internet connection: \(urlError.localizedDescription)")
        case .secureConnectionFailed:
            return .securityError("Secure connection failed: \(urlError.localizedDescription)")
        default:
            return .networkError("Network error: \(urlError.localizedDescription)")
        }
    }
}