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
    
    /// Holds the delegate strongly: `LimechatWidget.delegate` is weak, so an inline delegate would be freed
    public final class Coordinator {
        var delegate: LimechatWidgetDelegate?
        
        init(delegate: LimechatWidgetDelegate?) {
            self.delegate = delegate
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(delegate: delegate)
    }
    
    public func makeUIView(context: Context) -> LimechatWidget {
        return LimechatWidget(
            configuration: configuration,
            customButton: customButton,
            delegate: context.coordinator.delegate
        )
    }
    
    public func updateUIView(_ uiView: LimechatWidget, context: Context) {
        update(uiView, coordinator: context.coordinator)
    }
    
    func update(_ uiView: LimechatWidget, coordinator: Coordinator) {
        coordinator.delegate = delegate
        if uiView.delegate !== delegate { uiView.delegate = delegate }
    }
}
