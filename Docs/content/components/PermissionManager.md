# PermissionManager.swift

**Path:** `OpenOSUse/OpenOSUse/PermissionManager.swift`

A `@MainActor` singleton that manages the two macOS privacy permissions required by OpenOSUse.

## Permissions

| Permission | Framework | Check Method | Prompt Method |
|---|---|---|---|
| **Accessibility** | `ApplicationServices` | `AXIsProcessTrusted()` | `AXIsProcessTrustedWithOptions(kAXTrustedCheckOptionPrompt)` + opens System Settings pane |
| **Screen Recording** | `ScreenCaptureKit` | `CGPreflightScreenCaptureAccess()` (macOS 14+) or `SCShareableContent.current` | `CGRequestScreenCaptureAccess()` (macOS 14+) + opens System Settings pane |

## Published State

- `accessibilityGranted: Bool`
- `screenRecordingGranted: Bool`

Both are `@Published` so the SwiftUI dashboard reacts immediately when permissions change.

## Methods

| Method | Behaviour |
|---|---|
| `refreshAll()` | Re-checks both permissions asynchronously |
| `requestAccessibilityPermission()` | Prompts the user with the Accessibility permission dialog and opens System Settings |
| `requestScreenRecordingPermission()` | Prompts the user with the Screen Recording permission dialog and opens System Settings |

## Notes

- On macOS 13, Screen Recording permission is checked by attempting to enumerate `SCShareableContent.current` — if it throws, permission is denied
- The System Settings deep links (`x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`) guide the user to the correct pane
