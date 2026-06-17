# AgentOrchestrationLoop.swift

**Path:** `OpenOSUse/OpenOSUse/AgentOrchestrationLoop.swift`

A `@MainActor` ObservableObject singleton that runs the 5-state agent loop, coordinating between `ScreenCaptureEngine`, `SystemAutomationEngine`, `AXElementReader`, and the TypeScript gateway server.

## Agent States

```
┌──────────┐    ┌────────┐    ┌───────────┐    ┌────────────┐
│ OBSERVE  │───▶│  PLAN  │───▶│  EXECUTE  │───▶│ COOL DOWN  │
└──────────┘    └────────┘    └───────────┘    └────────────┘
                                                   │
                                                   ▼
                                               ┌──────────┐
                                               │  REPEAT   │───▶ OBSERVE
                                               └──────────┘
```

| State | Action |
|---|---|
| **OBSERVE** | Captures screenshot (if `useScreenshot` is enabled) via `ScreenCaptureEngine.shared.captureScreenshot()`; reads AX tree (if `useAXTree` is enabled) |
| **PLAN** | Base64-encodes screenshot, reads API key from Keychain, POSTs to gateway server. If `useVisionModel` and vision model differs from chat model, a two-step pipeline is used |
| **EXECUTE** | Dispatches the returned tool call through `SystemAutomationEngine`. First `click` or `click_element` per session prompts Touch ID |
| **COOL DOWN** | Sleeps for `coolDownMs` (default 500ms) to let the UI settle |
| **REPEAT** | Loops back to OBSERVE unless the tool was `finish` |

## Published State

| Property | Type | Description |
|---|---|---|
| `isRunning` | `Bool` | Whether the agent loop is active |
| `currentState` | `AgentState` | Current state name |
| `currentAction` | `String` | Human-readable description of the current action |
| `stepCount` | `Int` | Number of steps executed this session |
| `lastError` | `String?` | Most recent error message |
| `telemetryLogs` | `[TelemetryEntry]` | Ordered log of all events |
| `objective` | `String` | The original objective text |

## Configuration (set before calling `start()`)

| Property | Default | Description |
|---|---|---|
| `serverURL` | `http://localhost:3000/api/agent/step` | Gateway server URL |
| `provider` | `"anthropic"` | Provider key |
| `modelName` | `"claude-3-5-sonnet-20241022"` | Chat model name |
| `visionModelName` | `"claude-3-5-sonnet-20241022"` | Vision model name |
| `coolDownMs` | `500` | Pause between steps |
| `useAXTree` | `false` | Read Accessibility Tree |
| `useScreenshot` | `true` | Capture screenshots |
| `useVisionModel` | `true` | Use separate vision model |

## Conditional Pipeline

The agent adapts its behavior based on toggle settings:

- **Screenshot OFF + Vision OFF**: No screen capture. Chat model receives only objective + history + AX tree text. Uses `click_element` for UI targeting via AX tree.
- **Screenshot ON + Vision OFF**: Screen captured and sent directly to chat model (no two-step pipeline).
- **Screenshot ON + Vision ON + different models**: Two-step pipeline — vision model describes screenshot, chat model decides next action.
- **Screenshot ON + Vision ON + same model**: Single step — image sent directly to the model.

## Touch ID Verification

Before the first `click` or `click_element` in each session, the user is prompted for **Touch ID** authentication. The `clickAuthorized` flag resets at the start of each new agent session (`reset()`).

```swift
private func authorizeClick() async -> Bool {
    let context = LAContext()
    // evaluates .deviceOwnerAuthenticationWithBiometrics
    // caches result in clickAuthorized for the session
}
```

## DTOs

| Type | Purpose |
|---|---|
| `TelemetryEntry` | Identifiable log entry with timestamp, state, step, and message |
| `JSONValue` | Recursive JSON enum for decoding arbitrary tool arguments |
| `HistoryEntry` | Codable struct for replaying previous tool calls |
| `StepRequest` | Encodable body sent to the gateway (`screenshot` is optional) |
| `StepResponse` | Decodable response from the gateway |

## Error Handling

- Missing Keychain key → logs error and returns `nil` (loop continues, error displayed in UI)
- Server 4xx/5xx → `lastError` is set, loop continues
- Capture failure → loop terminates with `finish()`
- Touch ID failure → returns error string to model, loop continues
- Tool dispatch failures → result string includes error details, loop continues
