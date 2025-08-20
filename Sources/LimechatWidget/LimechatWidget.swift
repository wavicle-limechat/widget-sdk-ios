import UIKit
import SwiftUI

/// Main Limechat Widget component - iOS equivalent of React Native's LimeChatWidget
/// Handles both custom button and default icon rendering patterns
public class LimechatWidget: UIView {
    
    // MARK: - Properties
    
    /// Widget configuration
    public let configuration: WidgetConfiguration
    
    /// Optional custom button view (like React Native's customButton prop)
    public var customButton: UIView? {
        didSet {
            setupWidget()
        }
    }
    
    /// Widget delegate for callbacks
    public weak var delegate: LimechatWidgetDelegate?
    
    /// Style for the container (like React Native's style prop)
    public var containerStyle: [String: Any] = [:] {
        didSet {
            applyContainerStyle()
        }
    }
    
    /// Style for the default icon (like React Native's iconStyle prop)
    public var iconStyle: [String: Any] = [:] {
        didSet {
            applyIconStyle()
        }
    }
    
    /// Style for unread count badge (like React Native's unreadCountStyle prop)
    public var unreadCountStyle: [String: Any] = [:] {
        didSet {
            applyUnreadCountStyle()
        }
    }
    
    // MARK: - Private Properties
    
    private var widgetIcon: LimechatWidgetIcon?
    private var customButtonContainer: UIView?
    private var unreadCountBadge: UIView?
    private var unreadCount: Int = 0 {
        didSet {
            updateUnreadCount()
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize with configuration (required)
    /// - Parameters:
    ///   - configuration: Widget configuration with website token
    ///   - customButton: Optional custom button (like React Native's customButton prop)
    ///   - delegate: Widget delegate for callbacks
    public init(
        configuration: WidgetConfiguration,
        customButton: UIView? = nil,
        delegate: LimechatWidgetDelegate? = nil
    ) {
        self.configuration = configuration
        self.customButton = customButton
        self.delegate = delegate
        
        super.init(frame: .zero)
        setupWidget()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(configuration:customButton:delegate:) instead.")
    }
    
    // MARK: - Setup
    
    private func setupWidget() {
        // Clear existing views
        subviews.forEach { $0.removeFromSuperview() }
        widgetIcon = nil
        customButtonContainer = nil
        unreadCountBadge = nil
        
        if let customButton = customButton {
            setupCustomButton(customButton)
        } else {
            setupDefaultIcon()
        }
        
        setupUnreadCountBadge()
        applyStyles()
    }
    
    private func setupCustomButton(_ button: UIView) {
        // Like React Native: if customButton is provided, render it with onPress handling
        customButtonContainer = UIView()
        guard let container = customButtonContainer else { return }
        
        addSubview(container)
        container.addSubview(button)
        
        // Add tap gesture to custom button container
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleButtonPress))
        container.addGestureRecognizer(tapGesture)
        
        // Setup constraints
        container.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container fills this view
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Button fills container
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
    
    private func setupDefaultIcon() {
        // Like React Native: if no customButton, render default WidgetIcon from config
        widgetIcon = LimechatWidgetIcon()
        guard let icon = widgetIcon else { return }
        
        icon.initialize(with: configuration)
        icon.delegate = delegate
        
        addSubview(icon)
        
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: topAnchor),
            icon.leadingAnchor.constraint(equalTo: leadingAnchor),
            icon.trailingAnchor.constraint(equalTo: trailingAnchor),
            icon.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupUnreadCountBadge() {
        // Create unread count badge (like React Native's unread count display)
        unreadCountBadge = UIView()
        guard let badge = unreadCountBadge else { return }
        
        badge.backgroundColor = .systemRed
        badge.layer.cornerRadius = 10
        badge.isHidden = true
        
        let countLabel = UILabel()
        countLabel.textColor = .white
        countLabel.font = UIFont.boldSystemFont(ofSize: 12)
        countLabel.textAlignment = .center
        countLabel.tag = 999 // Tag to find label later
        
        badge.addSubview(countLabel)
        addSubview(badge)
        
        badge.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Badge in top-right corner
            badge.topAnchor.constraint(equalTo: topAnchor, constant: -5),
            badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 5),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            badge.heightAnchor.constraint(equalToConstant: 20),
            
            // Label fills badge
            countLabel.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            countLabel.leadingAnchor.constraint(greaterThanOrEqualTo: badge.leadingAnchor, constant: 4),
            countLabel.trailingAnchor.constraint(lessThanOrEqualTo: badge.trailingAnchor, constant: -4)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func handleButtonPress() {
        // Like React Native: handle both custom button onPress and widget toggle
        openWidget()
    }
    
    private func openWidget() {
        // Find the view controller and present widget
        guard let viewController = findViewController() else { return }
        
        let widgetVC = LimechatWidgetViewController(configuration: configuration)
        widgetVC.widgetDelegate = delegate
        
        viewController.present(widgetVC, animated: true)
    }
    
    // MARK: - Public Methods
    
    /// Update unread count (like React Native's automatic unread count update)
    public func setUnreadCount(_ count: Int) {
        unreadCount = count
    }
    
    // MARK: - Private Methods
    
    private func updateUnreadCount() {
        guard let badge = unreadCountBadge,
              let countLabel = badge.viewWithTag(999) as? UILabel else { return }
        
        if unreadCount > 0 {
            badge.isHidden = false
            countLabel.text = unreadCount > 99 ? "99+" : "\(unreadCount)"
        } else {
            badge.isHidden = true
        }
        
        // Also update widget icon if using default icon
        widgetIcon?.setUnreadCount(unreadCount)
    }
    
    private func applyStyles() {
        applyContainerStyle()
        applyIconStyle()
        applyUnreadCountStyle()
    }
    
    private func applyContainerStyle() {
        // Apply container styles (like React Native's style prop)
        // This can be extended to support more style properties
    }
    
    private func applyIconStyle() {
        // Apply icon styles (like React Native's iconStyle prop)
        guard let icon = widgetIcon else { return }
        
        if let size = iconStyle["size"] as? CGFloat {
            icon.iconSize = size
        }
        if let cornerRadius = iconStyle["cornerRadius"] as? CGFloat {
            icon.cornerRadius = cornerRadius
        }
        if let backgroundColor = iconStyle["backgroundColor"] as? UIColor {
            icon.backgroundColor = backgroundColor
        }
        if let tintColor = iconStyle["tintColor"] as? UIColor {
            icon.tintColor = tintColor
        }
    }
    
    private func applyUnreadCountStyle() {
        // Apply unread count styles (like React Native's unreadCountStyle prop)
        guard let badge = unreadCountBadge else { return }
        
        if let backgroundColor = unreadCountStyle["backgroundColor"] as? UIColor {
            badge.backgroundColor = backgroundColor
        }
        if let cornerRadius = unreadCountStyle["cornerRadius"] as? CGFloat {
            badge.layer.cornerRadius = cornerRadius
        }
    }
}

// MARK: - Helper Extension

private extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

// MARK: - SwiftUI Wrapper

/// SwiftUI wrapper for LimechatWidget (like React Native component usage)
public struct LimechatWidgetView: UIViewRepresentable {
    
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
        // Update if needed
    }
}
