import UIKit

/// Presentation style for the widget view controller
public enum WidgetPresentationStyle {
    case fullScreen
    case modal
    case popover
}

/// Full-screen view controller for presenting the Limechat widget
public class LimechatWidgetViewController: UIViewController {
    
    // MARK: - Properties
    
    private var widgetView: LimechatWidgetView!
    private var configuration: WidgetConfiguration
    private var presentationStyle: WidgetPresentationStyle
    private var navigationBar: UINavigationBar?
    
    public weak var widgetDelegate: LimechatWidgetDelegate?
    
    /// Whether to show a navigation bar (default: false)
    public var showNavigationBar: Bool = false {
        didSet {
            updateNavigationBarVisibility()
        }
    }
    
    /// Title to display in the navigation bar
    public var navigationTitle: String = "Support" {
        didSet {
            updateNavigationTitle()
        }
    }
    
    // MARK: - Initialization
    
    public init(configuration: WidgetConfiguration, presentationStyle: WidgetPresentationStyle = .fullScreen) {
        self.configuration = configuration
        self.presentationStyle = presentationStyle
        super.init(nibName: nil, bundle: nil)
        
        setupModalPresentation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWidget()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Send analytics event
        widgetView.sendMessage(event: "widget-presented", data: [
            "presentation_style": String(describing: presentationStyle)
        ])
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Send analytics event
        widgetView.sendMessage(event: "widget-dismissed")
    }
    
    public override var prefersStatusBarHidden: Bool {
        switch presentationStyle {
        case .fullScreen:
            return true
        case .modal, .popover:
            return false
        }
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    // MARK: - Setup
    
    private func setupModalPresentation() {
        switch presentationStyle {
        case .fullScreen:
            modalPresentationStyle = .fullScreen
            modalTransitionStyle = .coverVertical
        case .modal:
            modalPresentationStyle = .pageSheet
            if #available(iOS 13.0, *) {
                isModalInPresentation = true
            }
        case .popover:
            modalPresentationStyle = .popover
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        if showNavigationBar {
            setupNavigationBar()
        }
        
        setupWidgetView()
    }
    
    private func setupNavigationBar() {
        navigationBar = UINavigationBar()
        guard let navBar = navigationBar else { return }
        
        let navItem = UINavigationItem(title: navigationTitle)
        
        navBar.setItems([navItem], animated: false)
        view.addSubview(navBar)
        
        navBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupWidgetView() {
        widgetView = LimechatWidgetView()
        widgetView.delegate = self
        view.addSubview(widgetView)
        
        widgetView.translatesAutoresizingMaskIntoConstraints = false
        
        let topAnchor = navigationBar?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor
        
        NSLayoutConstraint.activate([
            widgetView.topAnchor.constraint(equalTo: topAnchor),
            widgetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            widgetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            widgetView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupWidget() {
        widgetView.initialize(with: configuration)
    }
    
    private func updateNavigationBarVisibility() {
        if showNavigationBar && navigationBar == nil {
            setupNavigationBar()
            updateWidgetViewConstraints()
        } else if !showNavigationBar && navigationBar != nil {
            navigationBar?.removeFromSuperview()
            navigationBar = nil
            updateWidgetViewConstraints()
        }
    }
    
    private func updateNavigationTitle() {
        navigationBar?.topItem?.title = navigationTitle
    }
    
    private func updateWidgetViewConstraints() {
        guard let widgetView = widgetView else { return }
        
        // Remove existing top constraint
        widgetView.constraints.forEach { constraint in
            if constraint.firstAttribute == .top {
                widgetView.removeConstraint(constraint)
            }
        }
        
        // Add new top constraint
        let topAnchor = navigationBar?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor
        widgetView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    }
    
    // MARK: - Public Methods
    
    /// Send a message to the widget
    public func sendMessage(event: String, data: [String: Any] = [:]) {
        widgetView.sendMessage(event: event, data: data)
    }
    
    /// Reload the widget
    public func reload() {
        widgetView.reload()
    }
    
    /// Get current widget state
    public var widgetState: WidgetState {
        return widgetView.currentState
    }
    
    /// Present the widget modally from a view controller
    public static func present(
        from viewController: UIViewController,
        configuration: WidgetConfiguration,
        presentationStyle: WidgetPresentationStyle = .fullScreen,
        delegate: LimechatWidgetDelegate? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let widgetVC = LimechatWidgetViewController(
            configuration: configuration,
            presentationStyle: presentationStyle
        )
        widgetVC.widgetDelegate = delegate
        viewController.present(widgetVC, animated: animated, completion: completion)
    }
}

// MARK: - LimechatWidgetDelegate

extension LimechatWidgetViewController: LimechatWidgetDelegate {
    public func widgetDidLoad() {
        widgetDelegate?.widgetDidLoad()
    }
    
    public func widgetDidRequestClose() {
        widgetDelegate?.widgetDidRequestClose()
        dismiss(animated: true)
    }
    
    public func widgetDidReceiveError(_ error: WidgetError) {
        widgetDelegate?.widgetDidReceiveError(error)
    }
    
    public func widgetDidReceiveMessage(_ message: [String: Any]) {
        widgetDelegate?.widgetDidReceiveMessage(message)
    }
    
    public func widgetDidReceiveUnreadCount(_ count: Int) {
        widgetDelegate?.widgetDidReceiveUnreadCount(count)
    }
}