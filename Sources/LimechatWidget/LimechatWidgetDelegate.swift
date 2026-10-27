import Foundation

/// Delegate protocol for widget events
public protocol LimechatWidgetDelegate: AnyObject {
    func widgetDidLoad()
    func widgetDidRequestClose()
    func widgetDidReceiveError(_ error: WidgetError)
    func widgetDidReceiveMessage(_ message: [String: Any])
    func widgetDidReceiveUnreadCount(_ count: Int)
    /// Called when the widget reports a new conversation token (`set-cw-conversation`).
    /// Same as android `WidgetCallback.onConversationTokenChange`.
    func widgetDidChangeConversationToken(_ token: String)
}

public extension LimechatWidgetDelegate {
    func widgetDidChangeConversationToken(_ token: String) {}
}
