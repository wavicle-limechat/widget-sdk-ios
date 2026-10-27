import UIKit

/// A floating widget icon that can be added to any view controller
public class LimechatWidgetIcon: UIView {
    
    // MARK: - Properties
    
    private var configuration: WidgetConfiguration?
    private var iconImageView: UIImageView!
    private var unreadCountLabel: UILabel?
    private var unreadCount: Int = 0 {
        didSet {
            updateUnreadCount()
        }
    }
    
    public weak var delegate: LimechatWidgetDelegate?
    
    /// Custom icon image (optional)
    public var customIcon: UIImage? {
        didSet {
            updateIcon()
        }
    }
    
    /// Icon size (default: 60x60)
    public var iconSize: CGFloat = 60
    
    /// Corner radius (default: 30)
    public var cornerRadius: CGFloat = 30 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    /// Tint color (default: white)
    public override var tintColor: UIColor! {
        get {
            return super.tintColor
        }
        set {
            super.tintColor = newValue
            iconImageView?.tintColor = newValue
        }
    }
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        backgroundColor = .systemBlue
        layer.cornerRadius = cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.2
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(iconTapped))
        addGestureRecognizer(tapGesture)
        
        iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        addSubview(iconImageView)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
            iconImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.6)
        ])
        
        updateIcon()
    }
    
    private func updateIcon() {
        if let customIcon = customIcon {
            iconImageView.image = customIcon
        } else {
            iconImageView.image = UIImage(systemName: "message.fill")
        }
    }
    
    private func updateUnreadCount() {
        if unreadCount > 0 {
            if unreadCountLabel == nil {
                unreadCountLabel = UILabel()
                unreadCountLabel?.backgroundColor = .systemRed
                unreadCountLabel?.textColor = .white
                unreadCountLabel?.font = .boldSystemFont(ofSize: 12)
                unreadCountLabel?.textAlignment = .center
                unreadCountLabel?.layer.cornerRadius = 10
                unreadCountLabel?.layer.masksToBounds = true
                unreadCountLabel?.translatesAutoresizingMaskIntoConstraints = false
                
                if let label = unreadCountLabel {
                    addSubview(label)
                    NSLayoutConstraint.activate([
                        label.topAnchor.constraint(equalTo: topAnchor, constant: -5),
                        label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 5),
                        label.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
                        label.heightAnchor.constraint(equalToConstant: 20)
                    ])
                }
            }
            unreadCountLabel?.text = unreadBadgeText(unreadCount)
        } else {
            unreadCountLabel?.removeFromSuperview()
            unreadCountLabel = nil
        }
    }
    
    // MARK: - Public Methods
    
    /// Initialize the widget icon with configuration
    public func initialize(with configuration: WidgetConfiguration) {
        self.configuration = configuration
    }
    
    /// Update unread count
    public func setUnreadCount(_ count: Int) {
        unreadCount = count
    }
    
    /// Present the widget when icon is tapped
    @objc private func iconTapped() {
        guard let configuration = configuration else {
            delegate?.widgetDidReceiveError(WidgetError.configurationError("Widget not initialized"))
            return
        }
        
        guard let viewController = findViewController() else {
            delegate?.widgetDidReceiveError(WidgetError.configurationError("Cannot find view controller"))
            return
        }
        
        LimechatWidgetViewController.present(
            from: viewController,
            configuration: configuration,
            delegate: delegate
        )
    }
    
}

/// Widget icon position options
public enum WidgetIconPosition {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

func unreadBadgeText(_ count: Int) -> String {
    count > 99 ? "99+" : "\(count)"
}
