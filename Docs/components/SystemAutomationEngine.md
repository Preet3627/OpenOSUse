# SystemAutomationEngine.swift

**Path:** `OpenOSUse/OpenOSUse/SystemAutomationEngine.swift`

A `@MainActor` singleton that translates high-level action commands into low-level Core Graphics and AppKit calls.

## Capabilities

### Application Management
- `openApplication(bundleIdentifier:)` — activates or launches an app by bundle ID

### Mouse Control
- `mouseMove(to:)` — warps cursor to a `CGPoint`
- `mouseMoveSmooth(to:duration:)` — interpolates cursor movement at ~60 fps
- `mouseClick(at:button:)` — moves to a point then posts `mouseDown` + `mouseUp`

### AX Element Clicking (native, no vision needed)
- `clickElement(label:role:) -> String` — finds a UI element by its on-screen label using the Accessibility API and clicks its center point

The `clickElement` method:
1. Reads the frontmost app's AX tree via `AXElementReader`
2. Recursively searches for an element matching `label` (by title, description, or value) and optional `role` (e.g. `"AXButton"`, `"AXTextField"`)
3. Gets the element's center coordinates from its position and size
4. Clicks at those coordinates using `mouseClick(at:)`

This is the **preferred method** for targetting UI elements — it works regardless of window size, display resolution, or Retina scaling.

### Keyboard Control
- `typeText(string:)` — types each character via `CGEvent` keyboard events
- `triggerKeyCombination(_:)` — presses modifier+key combos (e.g. `["cmd", "space"]`)

### Coordinate Scaling
```swift
struct CoordinateScaler {
    let captureWidth: CGFloat      // 1280 (vision canvas width)
    let captureHeight: CGFloat
    var scaleX: CGFloat            // screen.width / captureWidth
    var scaleY: CGFloat            // screen.height / captureHeight
    func mapToPhysical(_ modelPoint: CGPoint) -> CGPoint
}
```

Converts coordinates from the 1280px-wide vision canvas to physical Retina points.

## Key Mapping Tables

| Table | Contents |
|---|---|
| `keys_letters` | a–z → HID keycodes |
| `keys_numbers` | 0–9 and shifted symbols `!@#$%^&*()` |
| `keys_symbols` | `-_=+[{]}\|;:'\",<.>/?` and shifted variants |
| `namedKey` | Named keys: space, return, tab, escape, delete, arrows, F1–F12, home, end, pageup, pagedown |
| `modifierFlag(for:)` | Maps strings like `"cmd"`, `"shift"`, `"opt"`, `"ctrl"`, `"fn"`, `"caps"` to `CGEventFlags` |

## Notes

- `typeText` handles shift-sensitive characters automatically via the `maskShift` flag
- `CGAssociateMouseAndMouseCursorPosition` takes `boolean_t` (Int32) — `1` to re-associate, `0` to disassociate
- `charToKey` maps lowercase, uppercase, and whitespace characters
- `clickElement` uses recursive depth-first search on the AX tree (max depth: 12)
