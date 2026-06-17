# AgentOrchestrationLoop.swift

**Path:** `OpenOSUse/OpenOSUse/AgentOrchestrationLoop.swift`

The brain of the application. A `@MainActor` ObservableObject that runs the 5-state agent loop and coordinates between `ScreenCaptureEngine`, `SystemAutomationEngine`, and the TypeScript gateway server.

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
| **OBSERVE** | Captures a screenshot via `ScreenCaptureEngine.shared.captureScreenshot()` |
| **PLAN** | Base64-encodes the screenshot, reads the API key from Keychain, POSTs to the gateway server with `X-Provider-API-Key` and `X-Target-Provider` headers |
| **EXECUTE** | Dispatches the returned tool call through `SystemAutomationEngine` (click, type, key combo, open app, wait) |
| **COOL DOWN** | Sleeps for `coolDownMs` (default 500ms) to let the UI settle |
| **REPEAT** | Loops back to OBSERVE unless the tool was `finish` |

## Published State

| Property | Type | Description |
|---|---|---|
| `isRunning` | `Bool` | Whether the agent loop is active |
| `currentState` | `AgentState` | Current state name (Idle, OBSERVE, PLAN, EXECUTE, COOL DOWN) |
| `currentAction` | `String` | Human-readable description of the current action |
| `stepCount` | `Int` | Number of steps executed this session |
| `lastError` | `String?` | Most recent error message |
| `telemetryLogs` | `[TelemetryEntry]` | Ordered log of all events |

## Configuration (set before calling `start()`)

- `serverURL` — defaults to `http://localhost:3000/api/agent/step`
- `provider` — `"anthropic"`, `"google"`, `"groq"`, `"grok"`, or `"ollama"`
- `modelName` — model string passed to the provider
- `coolDownMs` — pause between steps (default: 500)

## DTOs

The file also defines the data types used for server communication:

| Type | Purpose |
|---|---|
| `TelemetryEntry` | Identifiable log entry with timestamp, state, step, and message |
| `JSONValue` | Recursive JSON enum for decoding arbitrary tool arguments |
| `HistoryEntry` | Codable struct for replaying previous tool calls |
| `StepRequest` | Encodable body sent to the gateway |
| `StepResponse` | Decodable response from the gateway |

## Error Handling

- Missing Keychain key → logs error and returns `nil` (loop continues, error displayed in UI)
- Server 4xx/5xx → `lastError` is set, loop continues
- Capture failure → loop terminates with `finish()`
- Tool dispatch failures → result string includes error details, loop continues
