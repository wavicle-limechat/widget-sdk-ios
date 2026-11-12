import SwiftUI
import UIKit
import LimechatWidget

/// Delegate that shows the last widget event on screen
final class EventLog: NSObject, ObservableObject, LimechatWidgetDelegate {
    @Published var last = "no events yet"

    private func post(_ text: String) {
        DispatchQueue.main.async { self.last = text }
    }

    func widgetDidLoad() { post("loaded") }
    func widgetDidRequestClose() { post("close requested") }
    func widgetDidReceiveError(_ error: WidgetError) { post("error: \(error)") }
    func widgetDidReceiveMessage(_ message: [String: Any]) { post("message: \(message)") }
    func widgetDidReceiveUnreadCount(_ count: Int) { post("unread: \(count)") }
    func widgetDidChangeConversationToken(_ token: String) { post("conversation token changed") }
}

/// Holds the live widget so the buttons can call it. The widgets are owned by the view hierarchy
final class WidgetHandle: ObservableObject {
    weak var controller: LimechatWidgetViewController?
    weak var launcher: LimechatWidget?
}

struct ActionRow: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(title, action: action).buttonStyle(.bordered)
    }
}

// MARK: - 1. UIKit LimechatWidgetViewController

struct UIKitDemo: View {
    let identified: Bool
    @StateObject private var log = EventLog()
    @StateObject private var handle = WidgetHandle()

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ActionRow(title: "Open message") { handle.controller?.open(message: "Hello from the example app") }
                ActionRow(title: "Open data") { handle.controller?.open(messageData: ExampleConfig.messageData) }
            }
            HStack {
                ActionRow(title: "Attributes") { _ = handle.controller?.setMessageAttributes(ExampleConfig.messageAttributes) }
                ActionRow(title: "Reload") { handle.controller?.reload() }
                ActionRow(title: "Reset") { handle.controller?.reset() }
            }
            Text(log.last).font(.footnote).lineLimit(2)
            ControllerHost(identified: identified, handle: handle, log: log)
        }
        .padding(.horizontal)
        .navigationTitle("UIKit view controller")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ControllerHost: UIViewControllerRepresentable {
    let identified: Bool
    let handle: WidgetHandle
    let log: EventLog

    func makeUIViewController(context: Context) -> LimechatWidgetViewController {
        let controller = LimechatWidgetViewController(configuration: ExampleConfig.configuration(identified: identified))
        controller.widgetDelegate = log
        handle.controller = controller
        return controller
    }

    func updateUIViewController(_ uiViewController: LimechatWidgetViewController, context: Context) {}
}

// MARK: - 2. LimechatWidgetSwiftUIView

struct SwiftUIDemo: View {
    let identified: Bool
    @StateObject private var log = EventLog()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 8) {
                Text("Tap the icon to open the widget.")
                Text("This wrapper has no open, reset or reload calls. Use the UIKit or launcher demo for those.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(log.last).font(.footnote).lineLimit(2)
                Spacer()
            }
            .padding()
            LimechatWidgetSwiftUIView(configuration: ExampleConfig.configuration(identified: identified), delegate: log)
                .frame(width: 60, height: 60)
                .padding()
        }
        .navigationTitle("SwiftUI view")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 3. LimechatWidget launcher

struct LauncherDemo: View {
    let identified: Bool
    @StateObject private var log = EventLog()
    @StateObject private var handle = WidgetHandle()

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ActionRow(title: "Open message") { handle.launcher?.open(message: "Hello from the launcher") }
                ActionRow(title: "Open data") { handle.launcher?.open(messageData: ExampleConfig.messageData) }
            }
            HStack {
                ActionRow(title: "Attributes") { _ = handle.launcher?.setMessageAttributes(ExampleConfig.messageAttributes) }
                ActionRow(title: "Reset") { handle.launcher?.reset() }
            }
            Text(log.last).font(.footnote).lineLimit(2)
            LauncherHost(identified: identified, handle: handle, log: log)
        }
        .padding(.horizontal)
        .navigationTitle("Launcher icon")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LauncherHost: UIViewControllerRepresentable {
    let identified: Bool
    let handle: WidgetHandle
    let log: EventLog

    func makeUIViewController(context: Context) -> UIViewController {
        let host = UIViewController()
        let widget = LimechatWidget(configuration: ExampleConfig.configuration(identified: identified), delegate: log)
        widget.translatesAutoresizingMaskIntoConstraints = false
        host.view.addSubview(widget)
        NSLayoutConstraint.activate([
            widget.widthAnchor.constraint(equalToConstant: 60),
            widget.heightAnchor.constraint(equalToConstant: 60),
            widget.trailingAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            widget.bottomAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
        handle.launcher = widget
        return host
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
