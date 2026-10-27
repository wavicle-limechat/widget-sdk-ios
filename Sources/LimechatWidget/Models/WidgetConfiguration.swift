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
    
    /// Base URL for the widget (optional, defaults to production)
    public let baseURL: String
    
    /// External conversation token (android `conversationToken`). when set, it is used instead of the stored one
    public let conversationToken: String?
    
    /// External token management (android `onConversationTokenChange`). when set, the sdk does not persist tokens
    public let onConversationTokenChange: ((String) -> Void)?
    
    /// Storage key for the internally managed token (android `instanceId`). nil or blank -> "default"
    public let instanceId: String?
    
    /// Color scheme options
    public enum ColorScheme: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case auto = "auto"
        
        /// Get system color scheme
        public static var system: ColorScheme {
            switch UIScreen.main.traitCollection.userInterfaceStyle {
            case .dark:
                return .dark
            default:
                return .light
            }
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
        customAttributes: [String: Any]? = nil,
        baseURL: String = "https://app.limechat.ai",
        conversationToken: String? = nil,
        onConversationTokenChange: ((String) -> Void)? = nil,
        instanceId: String? = nil
    ) {
        self.websiteToken = websiteToken
        self.locale = locale
        self.colorScheme = colorScheme
        self.user = user
        self.customAttributes = customAttributes
        self.baseURL = baseURL
        self.conversationToken = conversationToken
        self.onConversationTokenChange = onConversationTokenChange
        self.instanceId = instanceId
    }
    
    /// Build the widget URL with parameters
    var widgetURL: URL? {
        widgetURL(cwConversation: nil)
    }
    
    /// Build the widget URL; `cwConversation` wins over `conversationToken` (android `UrlBuilder`)
    func widgetURL(cwConversation: String?) -> URL? {
        guard !websiteToken.isEmpty else { return nil }
        
        var components = URLComponents(string: baseURL)
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
        
        // Conversation token
        if let token = cwConversation ?? conversationToken,
           !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "cw_conversation", value: token))
        }
        
        components?.queryItems = queryItems
        // URLQueryItem leaves `+` raw, which form decoders read as a space
        let encodedQuery = components?.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        components?.percentEncodedQuery = encodedQuery
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