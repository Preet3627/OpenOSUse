# SystemAutomationEngine.swift

**Path:** `OpenOSUse/OpenOSUse/SystemAutomationEngine.swift`

A `@MainActor` singleton that translates high-level action commands into low-level Core Graphics and AppKit calls.

## Capabilities

### Application Management
- `openApplication(bundleIdentifier:)` — activates an already-running app by bundle ID, or launches it via `NSWorkspace`

### Mouse Control
- `mouseMove(to:)` — warps the cursor to a `CGPoint` using `CGWarpMouseCursorPosition` + `CGAssociateMouseAndMouseCursorPosition`
- `mouseMoveSmooth(to:duration:)` — interpolates cursor movement over `duration` seconds at ~60 fps for smooth visual transitions
- `mouseClick(at:button:)` — moves to a point then posts `mouseDown` + `mouseUp` events via `CGEvent`

### Keyboard Control
- `typeText(string:)` — types each character by looking up its keycode/ shift-state in the internal `charToKey` table and posting `CGEvent` keyboard events
- `triggerKeyCombination(_:)` — presses a modifier+key combination (e.g. `["cmd", "space"]`)

### Coordinate Scaling
```swift
struct CoordinateScaler {
    let captureWidth: CGFloat
    let captureHeight: CGFloat
    var scaleX: CGFloat  // screen.width / captureWidth
    var scaleY: CGFloat  // screen.height / captureHeight
    func mapToPhysical(_ modelPoint: CGPoint) -> CGPoint
}
```

The scaler converts coordinates from the 1280px-wide vision canvas back to physical Retina points. This is critical because the LLM sees a downscaled canvas but mouse clicks must land on the actual display.

## Key Mapping Tables

| Table | Contents |
|---|---|
| `keys_letters` | a–z → HID keycodes |
| `keys_numbers` | 0–9 and shifted symbols `!@#$%^&*()` |
| `keys_symbols` | `` -_=+[{]}\|;:'\",<.>/?` and shifted variants |
| `namedKey` | Named keys: space, return, tab, escape, delete, arrows, F1–F12, home, end, pageup, pagedown |
| `modifierFlag(for:)` | Maps strings like `"cmd"`, `"shift"`, `"opt"`, `"ctrl"`, `"fn"`, `"caps"` to `CGEventFlags` |

## Notes

- `typeText` handles shift-sensitive characters automatically by setting/resetting the `maskShift` flag on each keystroke
- `CGAssociateMouseAndMouseCursorPosition(_:)` takes `boolean_t` (Int32) — `1` to re-associate, `0` to disassociate
- The `charToKey` dictionary maps both lowercase and uppercase variants, plus whitespace characters (`\t`, `\n`, `\r`)
