import UIKit

/// Full-screen view controller for presenting the Limechat widget
public class LimechatWidgetViewController: UIViewController {
    
    // MARK: - Properties
    
    private var widgetView: LimechatWidgetView!
    let configuration: WidgetConfiguration
    private var initialMessage: String?
    private var initialMessageData: [String: Any]?
    
    public weak var widgetDelegate: LimechatWidgetDelegate?
    
    // MARK: - Initialization
    
    public init(configuration: WidgetConfiguration, initialMessage: String? = nil, initialMessageData: [String: Any]? = nil) {
        self.configuration = configuration
        self.initialMessage = initialMessage
        self.initialMessageData = initialMessageData
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
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Setup
    
    private func setupModalPresentation() {
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .coverVertical
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupWidgetView()
    }
    
    private func setupWidgetView() {
        widgetView = LimechatWidgetView()
        widgetView.delegate = self
        view.addSubview(widgetView)
        
        widgetView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widgetView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            widgetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            widgetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            widgetView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupWidget() {
        widgetView.initialize(with: configuration, initialMessage: initialMessage, initialMessageData: initialMessageData)
    }
    
    // MARK: - Public Methods
    
    /// Send a message to the widget
    public func sendMessage(event: String, data: [String: Any] = [:]) {
        loadViewIfNeeded()
        widgetView.sendMessage(event: event, data: data)
    }
    
    /// Reload the widget and open it with a message
    public func open(message: String) {
        loadViewIfNeeded()
        widgetView.open(message: message)
    }
    
    /// Reload the widget and open it with a `{content, submitted_values}` payload
    public func open(messageData: [String: Any]) {
        loadViewIfNeeded()
        widgetView.open(messageData: messageData)
    }
    
    /// Reload the widget
    public func reload() {
        loadViewIfNeeded()
        widgetView.reload()
    }
    
    /// Present the widget modally from a view controller
    public static func present(
        from viewController: UIViewController,
        configuration: WidgetConfiguration,
        delegate: LimechatWidgetDelegate? = nil,
        initialMessage: String? = nil,
        initialMessageData: [String: Any]? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let widgetVC = LimechatWidgetViewController(configuration: configuration, initialMessage: initialMessage, initialMessageData: initialMessageData)
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
    
    public func widgetDidChangeConversationToken(_ token: String) {
        widgetDelegate?.widgetDidChangeConversationToken(token)
    }
}