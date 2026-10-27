import UIKit

/// Full-screen view controller for presenting the Limechat widget
public class LimechatWidgetViewController: UIViewController {
    
    // MARK: - Properties
    
    private var widgetView: LimechatWidgetView!
    private var configuration: WidgetConfiguration
    
    public weak var widgetDelegate: LimechatWidgetDelegate?
    
    // MARK: - Initialization
    
    public init(configuration: WidgetConfiguration) {
        self.configuration = configuration
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
        widgetView.initialize(with: configuration)
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
    
    /// Present the widget modally from a view controller
    public static func present(
        from viewController: UIViewController,
        configuration: WidgetConfiguration,
        delegate: LimechatWidgetDelegate? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let widgetVC = LimechatWidgetViewController(configuration: configuration)
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