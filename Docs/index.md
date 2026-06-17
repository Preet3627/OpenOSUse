# OpenOSUse

**OpenOSUse** is a macOS computer-use agent stack that lets an AI vision model observe your screen and control your mouse/keyboard to accomplish arbitrary desktop tasks. It consists of two parts:

- **Native macOS App** (SwiftUI) — captures screenshots, executes tool calls (click, type, key combos, open apps, wait), and orchestrates the agent loop.
- **TypeScript Gateway Server** (Express + Vercel AI SDK) — receives screenshots, sends them to an LLM provider (Anthropic, Google, Groq, Grok, or Ollama), and returns structured tool-call responses.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                 OpenOSUse.app (Swift)                │
│                                                     │
│  ┌──────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │Permission │  │ ScreenCapture  │  │SystemAuto-   │  │
│  │ Manager   │  │ Engine         │  │mationEngine  │  │
│  └────┬─────┘  └───────┬────────┘  └──────┬───────┘  │
│       │                │                  │          │
│  ┌────▼────────────────▼──────────────────▼───────┐  │
│  │           AgentOrchestrationLoop                │  │
│  │  OBSERVE → PLAN → EXECUTE → COOL DOWN → REPEAT  │  │
│  └────────────────────┬────────────────────────────┘  │
│                       │ HTTP POST (screenshot)        │
│                       │ + X-Provider-API-Key header   │
│                       ▼                               │
│              ┌──────────────────┐                     │
│              │ GatewayBinaryHost │ ← manages Process   │
│              └──────────────────┘                     │
└──────────────────────┬──────────────────────────────┘
                       │ localhost:3001
                       ▼
┌─────────────────────────────────────────────────────┐
│           OpenOSUseGateway (TypeScript)              │
│                                                     │
│  POST /api/agent/step                                │
│    → validates headers (provider, apiKey)            │
│    → builds messages + system prompt                 │
│    → routes to: Anthropic / Google / Groq / Grok / Ollama  │
│    → generateText({ toolChoice: "required" })        │
│    → returns { tool, arguments, thinking }           │
└─────────────────────────────────────────────────────┘
```

---

## Components

### Swift App (OpenOSUse.app)

| Component | File | Purpose |
|---|---|---|
| [App Entry Point](components/OpenOSUseApp.md) | `OpenOSUseApp.swift` | `@main` SwiftUI struct, launches gateway process, handles app lifecycle |
| [Dashboard UI](components/ContentView.md) | `ContentView.swift` | Permission status, objective input, agent controls (Go/Stop), telemetry log, settings |
| [Agent Settings](components/AgentSettings.md) | `AgentSettings.swift` | UserDefaults-backed settings, dual model config, model fetching |
| [Permission Manager](components/PermissionManager.md) | `PermissionManager.swift` | Requests and monitors Accessibility + Screen Recording permissions |
| [Screen Capture Engine](components/ScreenCaptureEngine.md) | `ScreenCaptureEngine.swift` | SCStream-based screen capture, ~30fps, 1280px max width, JPEG output |
| [System Automation Engine](components/SystemAutomationEngine.md) | `SystemAutomationEngine.swift` | Mouse move/click, AX element clicking, keyboard type/key combos, coordinate scaling, app launch |
| [Agent Orchestration Loop](components/AgentOrchestrationLoop.md) | `AgentOrchestrationLoop.swift` | 5-state agent loop, conditional pipeline, Touch ID auth, telemetry logging |
| [AX Element Reader](components/AXElementReader.md) | `AXElementReader.swift` | Reads Accessibility element tree of the frontmost app |
| [Model Fetcher](components/ModelFetcher.md) | `ModelFetcher.swift` | Provider-specific model list API calls |
| [MCP Server](components/MCPServer.md) | `MCPServer.swift` | Model Context Protocol server for remote agent control |
| [Keychain Manager](components/KeychainManager.md) | `KeychainManager.swift` | Securely stores/retrieves API keys via the macOS Security framework |
| [Coordinate Accuracy Test](components/CoordinateAccuracyTest.md) | `CoordinateAccuracyTest.swift` | Validates vision-canvas → physical-Retina coordinate transform |
| [Gateway Binary Host](components/GatewayBinaryHost.md) | `GatewayBinaryHost.swift` | Manages the TypeScript server as a child process |

### TypeScript Gateway Server

| Component | File | Purpose |
|---|---|---|
| [Server](server/gateway.md) | `server.ts` | Express app, Vercel AI SDK provider routing, tool definitions |
| [Configuration](server/configuration.md) | `package.json`, `tsconfig.json`, etc. | Project scaffolding, scripts, and build configuration |

---

## Data Flow

1. **OBSERVE** — if `useScreenshot` is enabled, `ScreenCaptureEngine` captures a screenshot. If `useAXTree` is enabled, `AXElementReader` reads the Accessibility element tree of the frontmost app. Both are optional.
2. **PLAN** — `AgentOrchestrationLoop` POSTs context (screenshot, AX tree, objective, history) to `localhost:3001/api/agent/step` with `X-Provider-API-Key` and `X-Target-Provider` headers. If `useVisionModel` is on and the vision model differs from the chat model, a two-step pipeline is used: vision model describes screenshot → chat model decides action.
3. The TypeScript **gateway** routes to the AI provider and calls `generateText({ toolChoice: "required" })`, returning `{ tool, arguments, thinking }`.
4. **EXECUTE** — `SystemAutomationEngine` performs the action. The first `click` or `click_element` per session prompts **Touch ID**. `click_element` finds UI elements by their AX label (no vision needed).
5. **COOL DOWN** — waits ~500ms for the UI to settle.
6. **REPEAT** — goes back to step 1 until `finish` is returned.

---

## Security Model

- **API keys never touch disk** — stored in the macOS Keychain via `KeychainManager`, injected as `X-Provider-API-Key` HTTP headers
- **Server never reads env vars for secrets** — the key arrives exclusively via the header; only `OLLAMA_BASE_URL` (a port/config URL) is read from `process.env`
- **Gateway runs with empty environment** — `process.environment = [:]` proves no terminal configuration is needed
- **App Sandbox disabled** — required for Accessibility (AX API) and Screen Recording (SCStream) permissions
- **Hardened Runtime disabled** — required for `CGEvent` posting and child process execution
- **Touch ID verification** — every agent session requires biometric authentication before the first click action executes. The `clickAuthorized` flag resets per session
