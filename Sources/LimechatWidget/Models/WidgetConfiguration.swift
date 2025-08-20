import Foundation
import UIKit

/// Configuration for the Limechat widget
public struct WidgetConfiguration {
    /// Your Limechat website token
    public let websiteToken: String
    
    /// Language locale (en, es, fr, de, it, pt, etc.)
    public let locale: String
    
    /// Color scheme for the widget
    public let colorScheme: ColorScheme
    
    /// User information
    public let user: User?
    
    /// Custom attributes to attach to the session
    public let customAttributes: [String: Any]?
    
    /// Color scheme options
    public enum ColorScheme: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case auto = "auto"
        
        /// Get system color scheme
        public static var system: ColorScheme {
            if #available(iOS 13.0, *) {
                switch UIScreen.main.traitCollection.userInterfaceStyle {
                case .dark:
                    return .dark
                default:
                    return .light
                }
            }
            return .light
        }
    }
    
    /// User information structure
    public struct User: Codable {
        public let name: String?
        public let email: String?
        public let phoneNumber: String?
        
        public init(
            name: String? = nil,
            email: String? = nil,
            phoneNumber: String? = nil
        ) {
            self.name = name
            self.email = email
            self.phoneNumber = phoneNumber
        }
        
        var dictionary: [String: Any] {
            var dict = [String: Any]()
            if let name = name { dict["name"] = name }
            if let email = email { dict["email"] = email }
            if let phoneNumber = phoneNumber { dict["phone_number"] = phoneNumber }
            return dict
        }
    }
    
    /// Initialize widget configuration
    public init(
        websiteToken: String,
        locale: String = "en",
        colorScheme: ColorScheme = .auto,
        user: User? = nil,
        customAttributes: [String: Any]? = nil
    ) {
        self.websiteToken = websiteToken
        self.locale = locale
        self.colorScheme = colorScheme
        self.user = user
        self.customAttributes = customAttributes
    }
    
    /// Build the widget URL with parameters
    var widgetURL: URL? {
        guard !websiteToken.isEmpty else { return nil }
        
        var components = URLComponents(string: "https://app.limechat.ai")
        components?.path = "/widget"
        
        var queryItems = [
            URLQueryItem(name: "website_token", value: websiteToken),
            URLQueryItem(name: "platform", value: "ios"),
            URLQueryItem(name: "locale", value: locale),
            URLQueryItem(name: "color_scheme", value: resolvedColorScheme.rawValue),
            URLQueryItem(name: "sdk_version", value: "1.0.0")
        ]
        
        // Add user parameters
        if let user = user {
            for (key, value) in user.dictionary {
                queryItems.append(URLQueryItem(name: key, value: "\(value)"))
            }
        }
        
        // Add custom attributes as JSON
        if let customAttributes = customAttributes,
           !customAttributes.isEmpty,
           let jsonData = try? JSONSerialization.data(withJSONObject: customAttributes),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            queryItems.append(URLQueryItem(name: "custom_attributes", value: jsonString))
        }
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    /// Resolve auto color scheme to actual value
    private var resolvedColorScheme: ColorScheme {
        if colorScheme == .auto {
            return ColorScheme.system
        }
        return colorScheme
    }
}