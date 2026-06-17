# OpenOSUseApp.swift

**Path:** `OpenOSUse/OpenOSUse/OpenOSUseApp.swift`

The `@main` entry point for the SwiftUI application. This struct conforms to the `App` protocol and is the first code that runs when the application launches.

## Responsibilities

- **Launch the gateway server** — in `init()`, calls `GatewayBinaryHost.shared.launchLocalGateway()` to start the TypeScript backend as a child process
- **Terminate the gateway on quit** — registers a `NotificationCenter` observer for `NSApplication.willTerminateNotification` that calls `GatewayBinaryHost.shared.terminateLocalGateway()`, ensuring clean shutdown
- **Present the dashboard** — renders `ContentView()` inside a `WindowGroup` scene with a minimum window size of 560×600

## Key Details

- Uses `NotificationCenter.default.addObserver(forName:object:queue:using:)` rather than SwiftUI's `.onReceive` because `Scene` protocol does not support that modifier
- The gateway launch is best-effort — if the `OpenOSUseGateway` binary is not found in the bundle, it logs a message and continues (the app remains usable for development scenarios)

```swift
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
```
