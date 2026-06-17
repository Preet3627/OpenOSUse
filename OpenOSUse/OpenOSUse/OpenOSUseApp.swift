import SwiftUI

@main
struct OpenOSUseApp: App {
    init() {
        do {
            try GatewayBinaryHost.shared.launchLocalGateway()
        } catch {
            print("[OpenOSUseApp] Failed to launch gateway: \(error)")
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            GatewayBinaryHost.shared.terminateLocalGateway()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 560, minHeight: 600)
        }
        .windowResizability(.contentSize)
    }
}
