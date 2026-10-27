import Foundation

extension WidgetConfiguration {
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
        
        if let user = user {
            for (key, value) in user.dictionary {
                queryItems.append(URLQueryItem(name: key, value: "\(value)"))
            }
        }
        
        if let customAttributes = customAttributes,
           !customAttributes.isEmpty,
           let jsonData = try? JSONSerialization.data(withJSONObject: customAttributes),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            queryItems.append(URLQueryItem(name: "custom_attributes", value: jsonString))
        }
        
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
    var resolvedColorScheme: ColorScheme {
        if colorScheme == .auto {
            return ColorScheme.system
        }
        return colorScheme
    }
}
