import UIKit
import WebKit

extension LimechatWidgetView {
    /// Script message handler names. the web posts objects to `limechat`.
    static let messageHandlerNames = ["limechat"]
    
    func handleConversationTokenUpdate(_ token: String?) {
        guard let token = token, !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        cwConversation = token
        
        if let onConversationTokenChange = configuration?.onConversationTokenChange {
            // external token management: the host persists the token
            onConversationTokenChange(token)
        } else {
            // internal token management: persist under instanceId
            ConversationTokenStore.save(token, instanceId: instanceId)
        }
        
        delegate?.widgetDidChangeConversationToken(token)
    }
    
    /// The widget posts set-cw-conversation in the same task that registers its message listener,
    /// so this is the first moment it can receive anything. Returns true the first time on this page.
    func markWidgetReady() -> Bool {
        guard pageStarted, !widgetReady else { return false }
        widgetReady = true
        sendVerifiedUser()
        if let message = pendingOpen {
            pendingOpen = nil
            sendMessage(event: "open-with-message", data: ["openMessage": message])
        }
        return true
    }

    func sendVerifiedUser() {
        guard let user = configuration?.user,
              let identifier = user.identifier, !identifier.isEmpty,
              let hash = user.identifierHash, !hash.isEmpty else { return }
        var fields = user.dictionary
        fields.removeValue(forKey: "phone_number")
        fields["identifier_hash"] = hash
        sendMessage(event: "set-user", data: ["identifier": identifier, "user": fields])
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
                let firstReady = markWidgetReady()
                handleConversationTokenUpdate(body["cw_conversation"] as? String)
                if firstReady { delegate?.widgetDidLoad() }
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
