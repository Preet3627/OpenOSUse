# Changelog

## [2.1.0] — 2026-06-17

### Added

- **Settings Persistence** — `AgentSettings` ObservableObject with UserDefaults-backed storage for provider, model name, server URL, cooldown, max retries, request timeout, AX tree toggle, and notifications toggle. New Settings tab in the UI.
- **Network Retry & Timeout** — Automatic retry (up to 3 attempts) when the agent server is unreachable, with configurable request timeout (default 30s).
- **System Notifications** — macOS notifications on agent finish or error (UNUserNotificationCenter). Configurable via Settings.
- **Telemetry Export** — Export full telemetry logs as JSON via file save dialog.
- **Objective Tracking** — `objective` published property on AgentOrchestrationLoop for notification context.
- **Codable Support** — TelemetryEntry and AgentState now conform to Codable for JSON export.

### Changed

- ContentView now includes a Settings tab with provider picker, model/server fields, sliders/steppers for tuning, toggles, and Apply/Export buttons.
- AgentOrchestrationLoop uses AgentSettings for retry count, timeout, notifications.

### Fixed

- Removed unused Double.nonzero extension.
- Fixed @MainActor isolation on AgentSettings.applyToOrchestrator().
- Fixed ReadConfiguration.file optional chaining for Swift 6 compatibility.

## [0.1.1] — 2026-06-17

### Added

- **Accessibility Tree Skill** — `AXElementReader` reads the structured AX element tree of the frontmost app (role, title, position, size, children) and returns it as JSON. The agent loop can now optionally use AX data alongside screenshots for richer environment perception.
- **MCP Protocol Server** — `MCPServer` listens on TCP port 8081 and exposes tools (`screenshot`, `axTree`, `click`, `type`, `open_app`) via JSON-RPC 2.0. Any MCP‑compatible client can drive the agent remotely.
- **Liquid Glass UI Redesign** — The dashboard has been redesigned with macOS Tahoe glass material aesthetics, sidebar‑adaptable navigation, floating panels, shimmer loading states for agent steps, and refined typography.
- **Release Workflow** — GitHub Actions workflow (`.github/workflows/release.yml`) triggered by tags `v*` that builds the Swift app and creates a GitHub release.

### Changed

- `AgentOrchestrationLoop` now accepts an optional `useAXTree` flag. When enabled, AX element data is captured and sent alongside the screenshot in each step.
- `ContentView` complete visual overhaul — modern glass‑material UI with animated transitions.

### Fixed

- N/A (initial feature release).

## [0.1.0] — 2026-06-10

### Added

- Screen capture engine using `ScreenCaptureKit` (~30 fps, 1280 px width).
- Five‑state agent orchestration loop: observe → plan → execute → cool down → finish.
- TypeScript/Express gateway server with Vercel AI SDK provider routing.
- Multi‑provider support: Anthropic Claude, Google Gemini, Groq, Grok (X.AI), Ollama.
- Permission manager with Accessibility + Screen Recording prompts.
- System automation engine: mouse click/move, keyboard type, key combos, app launch.
- Keychain‑based API key storage (never plaintext).
- Coordinate accuracy test tool.
- Telemetry dashboard showing live agent steps.
