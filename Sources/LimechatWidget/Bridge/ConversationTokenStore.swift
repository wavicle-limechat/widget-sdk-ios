import Foundation

/// Persists conversation tokens like the android sdk: storage `limechat_widget_conversations`,
/// key = `instanceId` (or `"default"`), shared in-memory cache in front.
enum ConversationTokenStore {
    static let storageName = "limechat_widget_conversations"
    static let defaultInstanceId = "default"
    static var defaults: UserDefaults = UserDefaults(suiteName: storageName) ?? .standard
    static var memoryCache: [String: String] = [:]

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
    }
}
