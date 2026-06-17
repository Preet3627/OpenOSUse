# ContentView.swift

**Path:** `OpenOSUse/OpenOSUse/ContentView.swift`

The main SwiftUI dashboard view. It is the single user interface the operator interacts with.

## Layout

```
┌─────────────────────────────────────────────┐
│  OpenOSUse                                  │
│  Permission Status                          │
├─────────────────────────────────────────────┤
│  ✅ Accessibility    Active                 │
│  ✅ Screen Recording Active                 │
├─────────────────────────────────────────────┤
│  [Objective…                   ] [Go]       │
│  [Test Coordinates] [Refresh Status]        │
├─────────────────────────────────────────────┤
│  Telemetry Log                              │
│  [14:32:01.123] [OBSERVE] Capturing...     │
│  [14:32:02.456] [PLAN]    Sending to...    │
│  [14:32:03.789] [EXECUTE] click(x,y) → ok  │
└─────────────────────────────────────────────┘
```

## States

### Idle (agent not running)
- Text field for entering the objective
- **Go** button to start the agent loop (disabled when empty)
- **Test Coordinates** — runs `CoordinateAccuracyTest.runAll()` which prints mapping tables then physically clicks each screen corner
- **Refresh Status** — re-checks Accessibility and Screen Recording permissions

### Running (agent active)
- Step counter and current state label (`OBSERVE`/`PLAN`/`EXECUTE`/`COOL DOWN`)
- Current action description
- **Stop** button to halt the agent

### Error
- Red warning text showing `orchestrator.lastError`

## Internal Components

### `PermissionRow`
A reusable row showing a permission title, description, and either a green **Active** badge or a **Grant Access** button.

### `TelemetryEntry` formatting
An extension on `TelemetryEntry` that formats log entries as `[HH:mm:ss.SSS] [STATE] message` using a monospaced font.
