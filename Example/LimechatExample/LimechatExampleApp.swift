import SwiftUI
import LimechatWidget

@main
struct LimechatExampleApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

struct RootView: View {
    @State private var identified = true

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Demos")) {
                    NavigationLink("UIKit view controller") { UIKitDemo(identified: identified) }
                    NavigationLink("SwiftUI view") { SwiftUIDemo(identified: identified) }
                    NavigationLink("Launcher icon") { LauncherDemo(identified: identified) }
                }
                Section(header: Text("Config"), footer: Text("Token: \(ExampleConfig.websiteToken)")) {
                    Toggle("Identify user", isOn: $identified)
                }
            }
            .navigationTitle("Limechat Example")
        }
        .navigationViewStyle(.stack)
    }
}
