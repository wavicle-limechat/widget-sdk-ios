// no SwiftUI import here: SwiftUI also has a `WidgetConfiguration`, so the name is ambiguous in files that import both
import Foundation
import LimechatWidget

/// Placeholder values. Put your own website token here (see Example/README.md).
enum ExampleConfig {
    static let websiteToken = "teDQSHiBCmtLRiMpwRQmqTT1"
    static let baseURL = "http://localhost:3000"
    static let instanceId = "limechat-example"

    static func configuration(identified: Bool) -> WidgetConfiguration {
        WidgetConfiguration(
            websiteToken: websiteToken,
            user: identified
                ? WidgetConfiguration.User(name: "Example User", email: "user@example.com", identifier: "example-user-1")
                : nil,
            baseURL: baseURL,
            instanceId: instanceId
        )
    }

    /// `submitted_values` only: the widget adds the default "Hi" content
    static let messageData: [String: Any] = ["submitted_values": ["order_id": "1234"]]
    static let messageAttributes: [String: Any] = ["plan": "pro", "source": "example-app"]
}
