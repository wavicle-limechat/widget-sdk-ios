import UIKit
import WebKit

extension LimechatWidgetView {
    /// Script message handler names. the web posts to `limechat`; `limechatNative` is kept.
    static let messageHandlerNames = ["limechat", "limechatNative"]
    static let messagePrefix = "limechat-widget:"
    
    func handleConversationTokenUpdate(_ token: String?) {
        guard let token = token, !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        if let onConversationTokenChange = configuration?.onConversationTokenChange {
            // external token management: the host persists the token
            onConversationTokenChange(token)
        } else {
            // internal token management: persist under instanceId
            cwConversation = token
            ConversationTokenStore.save(token, instanceId: instanceId)
        }
        
        delegate?.widgetDidChangeConversationToken(token)
    }
    
    /// Same as android `MessageHandler`: a dictionary, or a json object string with an optional `limechat-widget:` prefix.
    static func parseMessageBody(_ body: Any) -> [String: Any]? {
        if let dict = body as? [String: Any] {
            return dict
        }
        guard var string = body as? String else { return nil }
        if string.hasPrefix(messagePrefix) {
            string.removeFirst(messagePrefix.count)
        }
        guard let data = string.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let dict = json as? [String: Any] else {
            return nil
        }
        return dict
    }
}

// MARK: - WKScriptMessageHandler

extension LimechatWidgetView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard LimechatWidgetView.messageHandlerNames.contains(message.name),
              let body = LimechatWidgetView.parseMessageBody(message.body) else {
            return
        }
        
        if let event = (body["event"] as? String) ?? (body["type"] as? String) {
            switch event {
            case "close", "close-widget":
                delegate?.widgetDidRequestClose()
            case "set-cw-conversation":
                handleConversationTokenUpdate(body["cw_conversation"] as? String)
            case "unread_count":
                if let count = body["count"] as? Int {
                    delegate?.widgetDidReceiveUnreadCount(count)
                }
            default:
                delegate?.widgetDidReceiveMessage(body)
            }
        } else {
            delegate?.widgetDidReceiveMessage(body)
        }
    }
}
