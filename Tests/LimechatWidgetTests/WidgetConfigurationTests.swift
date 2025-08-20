import XCTest
@testable import LimechatWidget

final class WidgetConfigurationTests: XCTestCase {
    
    func testValidConfiguration() {
        let config = WidgetConfiguration(websiteToken: "test-token")
        
        XCTAssertEqual(config.websiteToken, "test-token")
        XCTAssertEqual(config.locale, "en")
        XCTAssertEqual(config.colorScheme, .auto)
        XCTAssertNil(config.user)
        XCTAssertNil(config.customAttributes)
        XCTAssertEqual(config.baseURL, "https://app.limechat.ai")
        XCTAssertFalse(config.enableDebugLogs)
        XCTAssertEqual(config.requestTimeout, 30.0)
    }
    
    func testConfigurationWithUser() {
        let user = WidgetConfiguration.User(
            name: "John Doe",
            email: "john@example.com",
            phoneNumber: "+1234567890",
            identifierHash: "abc123",
            avatarURL: "https://example.com/avatar.jpg"
        )
        
        let config = WidgetConfiguration(
            websiteToken: "test-token",
            user: user
        )
        
        XCTAssertEqual(config.user?.name, "John Doe")
        XCTAssertEqual(config.user?.email, "john@example.com")
        XCTAssertEqual(config.user?.phoneNumber, "+1234567890")
        XCTAssertEqual(config.user?.identifierHash, "abc123")
        XCTAssertEqual(config.user?.avatarURL, "https://example.com/avatar.jpg")
    }
    
    func testConfigurationValidation() {
        // Valid configuration should not throw
        let validConfig = WidgetConfiguration(websiteToken: "test-token")
        XCTAssertNoThrow(try validConfig.validate())
        
        // Empty token should throw
        let emptyTokenConfig = WidgetConfiguration(websiteToken: "")
        XCTAssertThrowsError(try emptyTokenConfig.validate()) { error in
            XCTAssertTrue(error is WidgetError)
            if case .configurationError(let message) = error as! WidgetError {
                XCTAssertTrue(message.contains("Website token"))
            }
        }
        
        // Invalid email should throw
        let invalidEmailUser = WidgetConfiguration.User(email: "invalid-email")
        let invalidEmailConfig = WidgetConfiguration(websiteToken: "test-token", user: invalidEmailUser)
        XCTAssertThrowsError(try invalidEmailConfig.validate()) { error in
            XCTAssertTrue(error is WidgetError)
        }
        
        // Invalid base URL should throw
        let invalidURLConfig = WidgetConfiguration(
            websiteToken: "test-token",
            baseURL: "not-a-url"
        )
        XCTAssertThrowsError(try invalidURLConfig.validate()) { error in
            XCTAssertTrue(error is WidgetError)
        }
    }
    
    func testWidgetURLGeneration() {
        let config = WidgetConfiguration(
            websiteToken: "test-token",
            locale: "fr",
            colorScheme: .dark
        )
        
        guard let url = config.widgetURL else {
            XCTFail("Failed to generate widget URL")
            return
        }
        
        XCTAssertTrue(url.absoluteString.contains("website_token=test-token"))
        XCTAssertTrue(url.absoluteString.contains("platform=ios"))
        XCTAssertTrue(url.absoluteString.contains("locale=fr"))
        XCTAssertTrue(url.absoluteString.contains("color_scheme=dark"))
        XCTAssertTrue(url.absoluteString.contains("sdk_version=1.0.0"))
    }
    
    func testWidgetURLWithCustomAttributes() {
        let customAttributes = [
            "source": "test",
            "version": "1.0.0"
        ]
        
        let config = WidgetConfiguration(
            websiteToken: "test-token",
            customAttributes: customAttributes
        )
        
        guard let url = config.widgetURL else {
            XCTFail("Failed to generate widget URL")
            return
        }
        
        XCTAssertTrue(url.absoluteString.contains("custom_attributes="))
    }
    
    func testUserDictionary() {
        let user = WidgetConfiguration.User(
            name: "John Doe",
            email: "john@example.com",
            phoneNumber: "+1234567890",
            identifierHash: "abc123",
            avatarURL: "https://example.com/avatar.jpg"
        )
        
        let dictionary = user.dictionary
        
        XCTAssertEqual(dictionary["name"] as? String, "John Doe")
        XCTAssertEqual(dictionary["email"] as? String, "john@example.com")
        XCTAssertEqual(dictionary["phone_number"] as? String, "+1234567890")
        XCTAssertEqual(dictionary["identifier_hash"] as? String, "abc123")
        XCTAssertEqual(dictionary["avatar_url"] as? String, "https://example.com/avatar.jpg")
    }
    
    func testColorSchemeSystem() {
        // This test may vary based on system appearance
        let systemColorScheme = WidgetConfiguration.ColorScheme.system
        XCTAssertTrue(systemColorScheme == .light || systemColorScheme == .dark)
    }
    
    func testEmptyTokenURL() {
        let config = WidgetConfiguration(websiteToken: "")
        XCTAssertNil(config.widgetURL)
    }
}
