import UIKit

/// Main Limechat Widget component
/// Handles both custom button and default icon rendering patterns
public class LimechatWidget: UIView {
    
    // MARK: - Properties
    
    /// Widget configuration
    public let configuration: WidgetConfiguration
    
    /// Optional custom button view
    public var customButton: UIView? {
        didSet {
            setupWidget()
        }
    }
    
    /// Widget delegate for callbacks
    public weak var delegate: LimechatWidgetDelegate? {
        didSet { widgetIcon?.delegate = delegate }
    }
    
    /// Style for the container
    public var containerStyle: [String: Any] = [:]
    
    /// Style for the default icon
    public var iconStyle: [String: Any] = [:] {
        didSet {
            applyIconStyle()
        }
    }
    
    /// Style for unread count badge
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
    ///   - customButton: Optional custom button
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
        customButtonContainer = UIView()
        guard let container = customButtonContainer else { return }
        
        addSubview(container)
        container.addSubview(button)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleButtonPress))
        container.addGestureRecognizer(tapGesture)
        
        container.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
    
    private func setupDefaultIcon() {
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
            badge.topAnchor.constraint(equalTo: topAnchor, constant: -5),
            badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 5),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            badge.heightAnchor.constraint(equalToConstant: 20),
            
            countLabel.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            countLabel.leadingAnchor.constraint(greaterThanOrEqualTo: badge.leadingAnchor, constant: 4),
            countLabel.trailingAnchor.constraint(lessThanOrEqualTo: badge.trailingAnchor, constant: -4)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func handleButtonPress() {
        openWidget()
    }
    
    private func openWidget() {
        open()
    }
    
    // MARK: - Public Methods
    
    /// Present the widget, optionally with a message or a `{content, submitted_values}` payload
    public func open(message: String? = nil, messageData: [String: Any]? = nil) {
        guard let viewController = findViewController() else { return }
        LimechatWidgetViewController.present(from: viewController, configuration: configuration, delegate: delegate, initialMessage: message, initialMessageData: messageData)
    }
    
    /// Update unread count
    public func setUnreadCount(_ count: Int) {
        unreadCount = count
    }
    
    // MARK: - Private Methods
    
    private func updateUnreadCount() {
        guard let badge = unreadCountBadge,
              let countLabel = badge.viewWithTag(999) as? UILabel else { return }
        
        if unreadCount > 0 {
            badge.isHidden = false
            countLabel.text = unreadBadgeText(unreadCount)
        } else {
            badge.isHidden = true
        }
    }
    
    private func applyStyles() {
        applyIconStyle()
        applyUnreadCountStyle()
    }
    
    private func applyIconStyle() {
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
        guard let badge = unreadCountBadge else { return }
        
        if let backgroundColor = unreadCountStyle["backgroundColor"] as? UIColor {
            badge.backgroundColor = backgroundColor
        }
        if let cornerRadius = unreadCountStyle["cornerRadius"] as? CGFloat {
            badge.layer.cornerRadius = cornerRadius
        }
    }
}
