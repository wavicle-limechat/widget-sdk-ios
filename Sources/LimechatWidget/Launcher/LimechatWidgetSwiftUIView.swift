import SwiftUI
import UIKit

/// SwiftUI wrapper for LimechatWidget
public struct LimechatWidgetSwiftUIView: UIViewRepresentable {
    
    public let configuration: WidgetConfiguration
    public let customButton: UIView?
    public let delegate: LimechatWidgetDelegate?
    
    public init(
        configuration: WidgetConfiguration,
        customButton: UIView? = nil,
        delegate: LimechatWidgetDelegate? = nil
    ) {
        self.configuration = configuration
        self.customButton = customButton
        self.delegate = delegate
    }
    
    public func makeUIView(context: Context) -> LimechatWidget {
        return LimechatWidget(
            configuration: configuration,
            customButton: customButton,
            delegate: delegate
        )
    }
    
    public func updateUIView(_ uiView: LimechatWidget, context: Context) {
    }
}
