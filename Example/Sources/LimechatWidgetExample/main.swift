import SwiftUI
import LimechatWidget

// MARK: - SwiftUI Example

struct ContentView: View {
    @State private var showWidget = false
    @State private var logs: [String] = ["App initialized"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Limechat Widget Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 15) {
                    Button(action: {
                        addLog("Opening widget manually")
                        showWidget = true
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Open Widget Manually")
                        }
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        addLog("Opening widget with floating icon")
                        showWidget = true
                    }) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Use Floating Icon (UIKit)")
                        }
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Activity Log")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(logs, id: \.self) { log in
                                Text(log)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showWidget) {
            WidgetViewWrapper(logs: $logs)
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    private func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logs.append("[\(timestamp)] \(message)")
    }
}

struct WidgetViewWrapper: UIViewControllerRepresentable {
    @Binding var logs: [String]
    
    func makeUIViewController(context: Context) -> LimechatWidgetViewController {
        let user = WidgetConfiguration.User(
            name: "John Doe",
            email: "john.doe@example.com",
            phoneNumber: "+1234567890"
        )
        
        let config = WidgetConfiguration(
            websiteToken: "MEFFACy4xaovJayhLjSt836h",
            locale: "en",
            user: user
        )
        
        let widgetVC = LimechatWidgetViewController(configuration: config)
        widgetVC.widgetDelegate = context.coordinator
        return widgetVC
    }
    
    func updateUIViewController(_ uiViewController: LimechatWidgetViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, LimechatWidgetDelegate {
        var parent: WidgetViewWrapper
        
        init(_ parent: WidgetViewWrapper) {
            self.parent = parent
        }
        
        func widgetDidLoad() {
            addLog("Widget loaded successfully")
        }
        
        func widgetDidRequestClose() {
            addLog("Widget closed")
        }
        
        func widgetDidReceiveError(_ error: WidgetError) {
            addLog("Widget error: \(error.localizedDescription)")
        }
        
        func widgetDidReceiveMessage(_ message: [String : Any]) {
            addLog("Widget message: \(message)")
        }
        
        func widgetDidReceiveUnreadCount(_ count: Int) {
            addLog("Unread count: \(count)")
        }
        
        private func addLog(_ message: String) {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            DispatchQueue.main.async {
                self.parent.logs.append("[\(timestamp)] \(message)")
            }
        }
    }
}

// MARK: - UIKit Example with Floating Icon

class UIKitExampleViewController: UIViewController, LimechatWidgetDelegate {
    
    private var widgetIcon: LimechatWidgetIcon!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        // Create configuration
        let user = WidgetConfiguration.User(
            name: "John Doe",
            email: "john.doe@example.com",
            phoneNumber: "+1234567890"
        )
        
        let configuration = WidgetConfiguration(
            websiteToken: "MEFFACy4xaovJayhLjSt836h",
            locale: "en",
            colorScheme: .auto,
            user: user,
            customAttributes: ["source": "ios_app"]
        )
        
        // Add floating widget icon - just one line!
        widgetIcon = addWidgetIcon(
            configuration: configuration,
            delegate: self,
            position: .bottomRight
        )
        
        // Customize the icon appearance
        widgetIcon.iconSize = 70
        widgetIcon.cornerRadius = 35
        widgetIcon.backgroundColor = .systemGreen
        widgetIcon.tintColor = .white
        
        // Add some UI elements
        let titleLabel = UILabel()
        titleLabel.text = "Limechat Widget Demo"
        titleLabel.font = .largeTitle
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Tap the floating green icon to open the widget"
        descriptionLabel.font = .body
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - LimechatWidgetDelegate
    
    func widgetDidLoad() {
        print("Widget loaded successfully")
    }
    
    func widgetDidRequestClose() {
        print("Widget closed")
    }
    
    func widgetDidReceiveError(_ error: WidgetError) {
        print("Widget error: \(error.localizedDescription)")
    }
    
    func widgetDidReceiveMessage(_ message: [String: Any]) {
        print("Widget message: \(message)")
    }
    
    func widgetDidReceiveUnreadCount(_ count: Int) {
        // Update the floating icon's unread count
        widgetIcon.setUnreadCount(count)
        print("Unread count updated: \(count)")
    }
}

// MARK: - UIKit Example with Manual Presentation

class UIKitManualExampleViewController: UIViewController, LimechatWidgetDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        // Add a button to manually open the widget
        let openButton = UIButton(type: .system)
        openButton.setTitle("Open Support Widget", for: .normal)
        openButton.titleLabel?.font = .title2
        openButton.backgroundColor = .systemBlue
        openButton.setTitleColor(.white, for: .normal)
        openButton.layer.cornerRadius = 10
        openButton.addTarget(self, action: #selector(openWidgetTapped), for: .touchUpInside)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Manual Widget Demo"
        titleLabel.font = .largeTitle
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Tap the button below to open the widget manually"
        descriptionLabel.font = .body
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(openButton)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            openButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 40),
            openButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            openButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            openButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func openWidgetTapped() {
        // Create configuration
        let user = WidgetConfiguration.User(
            name: "John Doe",
            email: "john.doe@example.com",
            phoneNumber: "+1234567890"
        )
        
        let configuration = WidgetConfiguration(
            websiteToken: "MEFFACy4xaovJayhLjSt836h",
            locale: "en",
            colorScheme: .auto,
            user: user,
            customAttributes: ["source": "ios_app"]
        )
        
        // Present widget manually
        LimechatWidgetViewController.present(
            from: self,
            configuration: configuration,
            delegate: self
        )
    }
    
    // MARK: - LimechatWidgetDelegate
    
    func widgetDidLoad() {
        print("Widget loaded successfully")
    }
    
    func widgetDidRequestClose() {
        print("Widget closed")
    }
    
    func widgetDidReceiveError(_ error: WidgetError) {
        print("Widget error: \(error.localizedDescription)")
    }
    
    func widgetDidReceiveMessage(_ message: [String: Any]) {
        print("Widget message: \(message)")
    }
    
    func widgetDidReceiveUnreadCount(_ count: Int) {
        print("Unread count: \(count)")
    }
}

#Preview {
    ContentView()
}