import Foundation

/// Persists conversation tokens like the android sdk: storage `limechat_widget_conversations`,
/// key = `instanceId` (or `"default"`), shared in-memory cache in front.
enum ConversationTokenStore {
    static let storageName = "limechat_widget_conversations"
    static let defaultInstanceId = "default"
    static var defaults: UserDefaults = UserDefaults(suiteName: storageName) ?? .standard
    static var memoryCache: [String: String] = [:]
    /// The last identity seen per instanceId, in process memory only. See `identity(of:)`
    static var identities: [String: String] = [:]

    static func load(instanceId: String) -> String? {
        if let token = memoryCache[instanceId] { return token }
        let token = defaults.string(forKey: instanceId)
        if let token = token { memoryCache[instanceId] = token }
        return token
    }

    static func save(_ token: String, instanceId: String) {
        memoryCache[instanceId] = token
        defaults.set(token, forKey: instanceId)
    }

    /// Forgets the token for this instance, in memory and in defaults
    static func clear(instanceId: String) {
        memoryCache[instanceId] = nil
        defaults.removeObject(forKey: instanceId)
        identities[instanceId] = nil
    }

    /// identifier, email and phone number joined with newlines, nil when all three are empty
    static func identity(of configuration: WidgetConfiguration) -> String? {
        let user = configuration.user
        let parts = [user?.identifier ?? "", user?.email ?? "", user?.phoneNumber ?? ""]
        return parts.allSatisfy { $0.isEmpty } ? nil : parts.joined(separator: "\n")
    }
}
