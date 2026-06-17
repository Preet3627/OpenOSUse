# GatewayBinaryHost.swift

**Path:** `OpenOSUse/OpenOSUse/GatewayBinaryHost.swift`

A utility singleton that manages the TypeScript gateway server (`OpenOSUseGateway`) as a child `Process` (NSTask). This eliminates the need for the user to run the server separately in a terminal.

## Methods

| Method | Behaviour |
|---|---|
| `launchLocalGateway()` | Locates `OpenOSUseGateway` in the app bundle via `Bundle.main.url(forResource:withExtension:)`, creates a `Process` with an **empty environment** (`environment = [:]`), and runs it |
| `terminateLocalGateway()` | Sends `SIGTERM` to the child process via `process.terminate()` and clears the reference |

## Key Design Decisions

- **Empty environment** — `process.environment = [:]` proves the gateway does not rely on shell profiles, PATH, or any terminal configuration. It is a self-contained binary.
- **`deinit` safety net** — if the `GatewayBinaryHost` is deallocated without an explicit `terminateLocalGateway()` call, the destructor kills the process automatically
- **Singleton pattern** — `GatewayBinaryHost.shared` is used throughout the app to ensure a single child process is tracked

## Error Handling

```swift
enum GatewayError: Error, LocalizedError {
    case binaryNotFound
    var errorDescription: String? {
        switch self {
        case .binaryNotFound:
            return "OpenOSUseGateway binary not found in app bundle"
        }
    }
}
```

The app logs the error and continues if the binary is missing — this allows development builds to work without the compiled gateway.

## Lifecycle

```
App.start → GatewayBinaryHost.shared.launchLocalGateway()
                ↓
         [Process runs OpenOSUseGateway on port 3001]
                ↓
App.quit  → GatewayBinaryHost.shared.terminateLocalGateway()  [via NSApplication.willTerminateNotification]
         → process.terminate()
```
