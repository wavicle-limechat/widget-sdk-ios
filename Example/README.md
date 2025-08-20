# iOS Example App

Since iOS apps require a proper Xcode project structure, here's how to create and run the example:

## Option 1: Quick Test with Package.swift

**Note**: This iOS SDK requires building with Xcode for iOS platform. Command-line Swift builds are not supported as this package uses UIKit which is iOS-only.

```bash
cd Example
# This will only work as a syntax check, not for actual building
swift package resolve
```

## Option 2: Create Full iOS App (Recommended)

1. **Create new iOS project in Xcode:**
   - File → New → Project
   - Choose "iOS" → "App"
   - Product Name: "LimechatExample"
   - Interface: SwiftUI
   - Language: Swift

2. **Add the SDK dependency:**
   - File → Add Packages
   - Enter local path: `/path/to/limechat-ios-sdk`
   - Or use: `https://github.com/limechat/limechat-ios-sdk.git`

3. **Replace ContentView.swift with:**

```swift
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
                    addLog("Opening widget in full-screen mode")
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
            colorScheme: .light,
            user: user,
            customAttributes: [
                "source": "ios_sample_app",
                "version": "1.0.0"
            ]
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
```

4. **Run the app:**
   - Select a simulator or device
   - Press ⌘R to run

## Testing the Widget

1. Tap "Open Widget" button
2. The widget will open in full-screen mode
3. You can interact with the Limechat support interface
4. Check the activity logs for events
5. Use the back gesture or widget close button to return

## Troubleshooting

- Make sure you have internet connectivity
- Verify the website token is correct
- Check that iOS deployment target is 13.0+
- Ensure Info.plist allows web content if needed