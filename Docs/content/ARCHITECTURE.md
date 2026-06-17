# Architecture Overview

## Layered Design

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│                ContentView.swift (SwiftUI)                   │
│  - Permission status, objective input, agent controls        │
│  - Telemetry log with auto-scroll                            │
│  - Sidebar navigation, MCP toggle, AX Tree toggle            │
│  - Liquid Glass / glass material aesthetic                   │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                   Orchestration Layer                        │
│             AgentOrchestrationLoop.swift                     │
│  - 5-state agent loop (OBSERVE → PLAN → EXECUTE → COOLDOWN) │
│  - Optional AX Tree capture alongside screenshots            │
│  - State management + telemetry logging                      │
│  - Server communication (URLSession)                         │
└────────────┬────────────────────────────┬───────────────────┘
             │                            │
┌────────────▼────────────┐  ┌────────────▼──────────────────┐
│    Capture Layer         │  │    Perception Layer            │
│ ScreenCaptureEngine.swift│  │ AXElementReader.swift          │
│ - SCStream screen capture│  │ - AXUIElement tree traversal   │
│ - 1280px max width       │  │ - Role, title, position, size  │
│ - ~30 fps, JPEG output   │  │ - Frontmost app snapshot       │
│ - Thread-safe frame buf  │  │ - JSON output                  │
└──────────────────────────┘  └───────────────────────────────┘
             │                            │
             └───────────┬────────────────┘
                         │
┌────────────────────────▼───────────────────────────────────┐
│                      Automation Layer                        │
│              SystemAutomationEngine.swift                    │
│  - Mouse move/click                                          │
│  - Keyboard type/key combos                                  │
│  - App launch                                                │
│  - CoordinateScaler                                          │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                      Data Layer                              │
│  - KeychainManager.swift (Secure API key storage)            │
│  - GatewayBinaryHost.swift (Child process management)        │
│  - MCPServer.swift (JSON-RPC 2.0 over TCP)                   │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│               Gateway Server (TypeScript)                    │
│  - Express POST /api/agent/step                              │
│  - Vercel AI SDK provider routing                            │
│  - toolChoice: "required" LLM integration                   │
│  - HTTP header-based API key injection                       │
└─────────────────────────────────────────────────────────────┘
```

## The 5-State Agent Loop

```
OBSERVE
  │ ScreenCaptureEngine.captureScreenshot()
  │ (optional) AXElementReader.readFrontmostAppTreeJSON()
  │ Returns JPEG Data → base64 encode (+ AX tree JSON)
  ▼
PLAN
  │ Read API key from KeychainManager
  │ POST to gateway with X-Provider-API-Key + X-Target-Provider headers
  │ Gateway routes to LLM provider, returns { tool, arguments }
  ▼
EXECUTE
  │ SystemAutomationEngine performs action:
  │   click  → mouseClick(at:)
  │   type   → typeText(string:)
  │   key_combo → triggerKeyCombination()
  │   open_app → openApplication(bundleIdentifier:)
  │   wait   → Task.sleep()
  │   finish → stop loop
  ▼
COOL DOWN (500ms)
  │ Wait for UI to settle
  ▼
REPEAT (back to OBSERVE)
```

## Coordinate Flow

```
LLM vision model sees 1280px-wide canvas
  ↓  returns click(x, y) in canvas space
CoordinateScaler.mapToPhysical()
  ↓  multiplies by screenWidth/1280, screenHeight/captureHeight
Physical Retina point
  ↓
CGWarpMouseCursorPosition + CGEvent post
```

## Security Boundaries

| Boundary | Mechanism |
|---|---|
| API key storage | macOS Keychain (`kSecClassGenericPassword`) |
| Key transport | HTTP header (`X-Provider-API-Key`) — never in URL, body, or env |
| Server key handling | Read from header only — no `process.env` fallback |
| Gateway process | Empty environment — no shell/PATH dependency |
| App sandbox | Disabled (required for AX API + SCStream) |
| Hardened runtime | Disabled (required for CGEvent + child process) |
