import UIKit
import WebKit

extension LimechatWidgetView {
    /// Script message handler names. the web posts objects to `limechat`.
    static let messageHandlerNames = ["limechat"]
    
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
}

// MARK: - WKScriptMessageHandler

extension LimechatWidgetView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard LimechatWidgetView.messageHandlerNames.contains(message.name),
              let body = message.body as? [String: Any] else {
            return
        }
        
        if let event = (body["event"] as? String) ?? (body["type"] as? String) {
            switch event {
            case "close-widget":
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
