# ContentView.swift

**Path:** `OpenOSUse/OpenOSUse/ContentView.swift`

The main SwiftUI view. Provides the dashboard, permissions management, MCP server controls, telemetry, and settings.

## Tabs

| Tab | Icon | Description |
|---|---|---|
| Dashboard | `square.grid.2x2` | Agent control, objective input, status, quick actions |
| Permissions | `lock.shield` | Accessibility + Screen Recording permission status |
| MCP Server | `link` | Model Context Protocol server controls |
| Telemetry | `chart.bar` | Live step-by-step agent log |
| Settings | `gearshape` | Provider, model, server, and feature configuration |

## Dashboard States

### Idle
- Text field for objective entry
- **Launch Agent** button (disabled when empty)
- Accessibility Tree toggle
- Quick actions: Test Coordinates, Refresh Status, Read AX Tree

### Running
- Step counter + state progress bar (`OBSERVE` → `PLAN` → `EXECUTE` → `COOL DOWN`)
- Current action description
- **Stop** button

### Error
- Orange warning card showing `orchestrator.lastError`

## Settings Tab

### Provider & Models
- **Provider** — dropdown of supported providers (Anthropic, Gemini, Groq, Grok, Ollama)
- **Chat Model** — dropdown populated from `availableModels` (or text field fallback if fetch failed)
- **Vision Model** — dropdown filtered to vision-capable models (or text field fallback)
- **Refresh** button next to each model picker to re-fetch models
- **Server URL** — text field for gateway server endpoint

### Tuning
- **Cooldown** slider (0–3000ms)
- **Max Retries** stepper (0–10)
- **Request Timeout** slider (5–120s)

### Feature Toggles
- **Accessibility Tree** — capture AX element data alongside screenshots
- **System Notifications** — macOS notifications on finish/error
- **Screenshots** — enable/disable screen capture (disables Vision Model toggle when off)
- **Vision Model** — enable/disable separate vision model for screenshot description

### Actions
- **Apply Settings** — copies current settings to `AgentOrchestrationLoop`
- **Export Telemetry** — saves telemetry logs as JSON

## Effects

- `ShimmerEffect` — animated gradient overlay on the running badge
- `PulseEffect` — pulsing green dot on the agent status card
