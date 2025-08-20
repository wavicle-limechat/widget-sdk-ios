import SwiftUI
import LimechatWidget

struct ContentView: View {
    @State private var showWidget = false
    @State private var logs: [String] = ["App initialized"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Limechat Widget Sample")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Button(action: {
                    addLog("Opening widget")
                    showWidget = true
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Open Widget")
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
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

#Preview {
    ContentView()
}