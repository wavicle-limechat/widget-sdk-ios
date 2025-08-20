import XCTest
@testable import LimechatWidget

final class WidgetErrorTests: XCTestCase {
    
    func testErrorCodes() {
        XCTAssertEqual(WidgetError.configurationError("test").errorCode, 1001)
        XCTAssertEqual(WidgetError.networkError("test").errorCode, 1002)
        XCTAssertEqual(WidgetError.webViewError("test").errorCode, 1003)
        XCTAssertEqual(WidgetError.javascriptError("test").errorCode, 1004)
        XCTAssertEqual(WidgetError.timeoutError("test").errorCode, 1005)
        XCTAssertEqual(WidgetError.securityError("test").errorCode, 1006)
        XCTAssertEqual(WidgetError.unknownError("test").errorCode, 1999)
    }
    
    func testErrorDescriptions() {
        let configError = WidgetError.configurationError("Invalid token")
        XCTAssertEqual(configError.errorDescription, "Configuration Error: Invalid token")
        
        let networkError = WidgetError.networkError("Connection failed", 404)
        XCTAssertEqual(networkError.errorDescription, "Network Error: Connection failed (HTTP 404)")
        
        let networkErrorNoCode = WidgetError.networkError("Connection failed")
        XCTAssertEqual(networkErrorNoCode.errorDescription, "Network Error: Connection failed")
    }
    
    func testRecoverySuggestions() {
        let configError = WidgetError.configurationError("test")
        XCTAssertNotNil(configError.recoverySuggestion)
        XCTAssertTrue(configError.recoverySuggestion!.contains("configuration"))
        
        let networkError = WidgetError.networkError("test")
        XCTAssertNotNil(networkError.recoverySuggestion)
        XCTAssertTrue(networkError.recoverySuggestion!.contains("internet"))
    }
    
    func testRecoverabilityFlags() {
        // Non-recoverable errors
        XCTAssertFalse(WidgetError.configurationError("test").isRecoverable)
        XCTAssertFalse(WidgetError.securityError("test").isRecoverable)
        
        // Recoverable errors
        XCTAssertTrue(WidgetError.networkError("test").isRecoverable)
        XCTAssertTrue(WidgetError.webViewError("test").isRecoverable)
        XCTAssertTrue(WidgetError.javascriptError("test").isRecoverable)
        XCTAssertTrue(WidgetError.timeoutError("test").isRecoverable)
        XCTAssertTrue(WidgetError.unknownError("test").isRecoverable)
    }
    
    func testFromURLError() {
        let timeoutError = URLError(.timedOut)
        let widgetError = WidgetError.from(timeoutError)
        
        if case .timeoutError(let message) = widgetError {
            XCTAssertTrue(message.contains("timed out"))
        } else {
            XCTFail("Expected timeout error")
        }
        
        let networkError = URLError(.notConnectedToInternet)
        let widgetNetworkError = WidgetError.from(networkError)
        
        if case .networkError(let message, _) = widgetNetworkError {
            XCTAssertTrue(message.contains("internet"))
        } else {
            XCTFail("Expected network error")
        }
        
        let securityError = URLError(.secureConnectionFailed)
        let widgetSecurityError = WidgetError.from(securityError)
        
        if case .securityError(let message) = widgetSecurityError {
            XCTAssertTrue(message.contains("Secure connection"))
        } else {
            XCTFail("Expected security error")
        }
    }
    
    func testDebugDescription() {
        let error = WidgetError.configurationError("test message")
        let debugDesc = error.debugDescription
        
        XCTAssertTrue(debugDesc.contains("WidgetError"))
        XCTAssertTrue(debugDesc.contains("1001"))
        XCTAssertTrue(debugDesc.contains("Configuration Error"))
    }
}
