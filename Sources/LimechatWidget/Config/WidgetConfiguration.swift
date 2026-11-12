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
    
    /// Hides the attachment button in the widget (`hide_file_picker`)
    public let hideFilePicker: Bool
    
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
    /// Who the host says the user is: identifier, email, phone and the external token. Name and attributes are not identity
    /// A token going from empty or nil to a value is not a switch (the host echoes it back after the first session).
    /// A token that changes from a non-empty value, or is cleared, is a switch. Empty and nil are the same
    func isSameIdentity(as new: WidgetConfiguration) -> Bool {
        let fields = { (c: WidgetConfiguration) in [c.user?.identifier, c.user?.email, c.user?.phoneNumber] }
        guard fields(self) == fields(new) else { return false }
        guard let old = conversationToken, !old.isEmpty else { return true }
        return new.conversationToken == old
    }

    public struct User: Codable {
        public let name: String?
        public let email: String?
        public let phoneNumber: String?
        public let identifier: String?
        public let identifierHash: String?
        /// Custom attributes of the user, sent with the rnUser script
        public private(set) var customAttributes: [String: Any]? = nil
        
        private enum CodingKeys: String, CodingKey {
            case name, email, phoneNumber, identifier, identifierHash
        }
        
        public init(
            name: String? = nil,
            email: String? = nil,
            phoneNumber: String? = nil,
            identifier: String? = nil,
            identifierHash: String? = nil,
            customAttributes: [String: Any]? = nil
        ) {
            self.name = name
            self.email = email
            self.phoneNumber = phoneNumber
            self.identifier = identifier
            self.identifierHash = identifierHash
            self.customAttributes = customAttributes
        }
        
        var dictionary: [String: Any] {
            var dict = [String: Any]()
            if let name = name { dict["name"] = name }
            if let email = email { dict["email"] = email }
            if let phoneNumber = phoneNumber { dict["phone_number"] = phoneNumber }
            if let customAttributes = customAttributes, JSONSerialization.isValidJSONObject(customAttributes) {
                dict["custom_attributes"] = customAttributes
            }
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
        instanceId: String? = nil,
        hideFilePicker: Bool = false
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
        self.hideFilePicker = hideFilePicker
    }
}

extension WidgetConfiguration {
    /// Same configuration with another `conversationToken`
    func replacingConversationToken(_ token: String?) -> WidgetConfiguration {
        WidgetConfiguration(
            websiteToken: websiteToken,
            locale: locale,
            colorScheme: colorScheme,
            user: user,
            customAttributes: customAttributes,
            baseURL: baseURL,
            conversationToken: token,
            onConversationTokenChange: onConversationTokenChange,
            instanceId: instanceId,
            hideFilePicker: hideFilePicker
        )
    }
    
    /// Under external token management the sdk stores nothing, so a launcher carries the live token
    /// into the next open. Otherwise the configuration is returned as is.
    func withLiveToken(_ token: String?) -> WidgetConfiguration {
        guard onConversationTokenChange != nil, let token = token, !token.isEmpty else { return self }
        return replacingConversationToken(token)
    }
}
