# OpenOSUse

**AI-powered macOS computer-use agent.** OpenOSUse lets a vision model observe your screen and control your mouse and keyboard to automate any desktop task — opening apps, clicking buttons, typing text, navigating menus, and more.

```
┌──────────────────────────┐     ┌──────────────────────────────┐
│  OpenOSUse.app (Swift)   │────▶│  OpenOSUseGateway (Node/TS)  │
│                          │     │                              │
│  Captures screenshots,   │     │  Routes to Anthropic, Google,│
│  executes tool calls     │     │  Groq, Grok, or Ollama       │
│  (click, type, key combo,│     │  Returns structured tool-call │
│  open app, wait, finish) │     │  responses via Vercel AI SDK  │
└──────────────────────────┘     └──────────────────────────────┘
```

## Quick Start

### Prerequisites

- macOS 13.0+ (Ventura)
- Xcode 16+
- Node.js 20+ (for building the gateway)
- An API key for at least one supported provider

### 1. Build the Gateway Server

```bash
cd server
npm install
npm run build       # compiles TypeScript → dist/
```

Bundle the output as `OpenOSUseGateway` and place it in the Xcode target's Resources (or use `npm run dev` during development).

### 2. Build & Run the App

```bash
open OpenOSUse.xcodeproj
# Select scheme: OpenOSUse
# Product → Run (⌘R)
```

The app will request **Accessibility** and **Screen Recording** permissions on first launch. Grant both in System Settings.

### 3. Configure an API Key

Use the in-app UI or the command line to store a provider key in the Keychain:

```swift
// Programmatic equivalent:
KeychainManager.shared.saveProviderKey(provider: "anthropic", key: "sk-ant-...")
```

### 4. Run an Agent

1. Enter an objective (e.g. "Open Safari and go to github.com")
2. Click **Go**
3. Watch the agent work — the telemetry log shows every step: capture, plan, execute, cooldown

## Supported AI Providers

| Provider | Model Example | Key Needed |
|---|---|---|
| **Anthropic** | `claude-3-5-sonnet-20241022` | Yes |
| **Google** | `gemini-2.5-flash` | Yes |
| **Groq** | `llama-3.3-70b-versatile` | Yes |
| **Grok (X.AI)** | `grok-2` | Yes |
| **Ollama** | `llama3.2-vision` | No (local) |

## Project Structure

```
OpenOSUse/
├── OpenOSUse.xcodeproj/       # Xcode project (manually maintained)
├── OpenOSUse/
│   ├── OpenOSUseApp.swift             # @main entry point
│   ├── ContentView.swift              # Dashboard UI
│   ├── PermissionManager.swift        # Accessibility + Screen Recording permissions
│   ├── ScreenCaptureEngine.swift      # SCStream screen capture (~30fps, 1280px)
│   ├── SystemAutomationEngine.swift   # Mouse, keyboard, app launch, coordinate scaling
│   ├── AgentOrchestrationLoop.swift   # 5-state agent loop + server communication
│   ├── KeychainManager.swift          # Secure API key storage
│   ├── CoordinateAccuracyTest.swift   # Coordinate transform validation
│   ├── GatewayBinaryHost.swift        # Child process management
│   ├── Info.plist
│   └── OpenOSUse.entitlements
└── server/
    ├── server.ts               # Express + Vercel AI SDK gateway
    ├── package.json
    ├── tsconfig.json
    ├── test_providers.sh       # Provider smoke-test script
    └── .env.example
```

## Documentation

Full component documentation is in the [`Docs/`](Docs/) directory:

| Page | Description |
|---|---|
| [Landing Page](Docs/index.md) | Architecture overview, data flow, security model |
| [ARCHITECTURE](Docs/ARCHITECTURE.md) | Layered architecture diagram and design decisions |
| [OpenOSUseApp](Docs/components/OpenOSUseApp.md) | App entry point and lifecycle |
| [ContentView](Docs/components/ContentView.md) | Dashboard UI layout and states |
| [PermissionManager](Docs/components/PermissionManager.md) | Permission handling |
| [ScreenCaptureEngine](Docs/components/ScreenCaptureEngine.md) | Screen capture internals |
| [SystemAutomationEngine](Docs/components/SystemAutomationEngine.md) | Mouse/keyboard automation |
| [AgentOrchestrationLoop](Docs/components/AgentOrchestrationLoop.md) | Agent loop and state machine |
| [KeychainManager](Docs/components/KeychainManager.md) | Keychain storage API |
| [CoordinateAccuracyTest](Docs/components/CoordinateAccuracyTest.md) | Coordinate transform testing |
| [GatewayBinaryHost](Docs/components/GatewayBinaryHost.md) | Child process lifecycle |
| [Gateway Server](Docs/server/gateway.md) | TypeScript server and provider routing |
| [Server Configuration](Docs/server/configuration.md) | package.json, tsconfig, scripts |

## Security

- **API keys stored in macOS Keychain** — never in plain-text files or config files
- **Header-based key injection** — keys arrive at the server via `X-Provider-API-Key`, never via environment variables or the request body
- **Empty process environment** — the gateway binary runs with `process.environment = [:]` to eliminate terminal/ shell dependencies
- **App Sandbox + Hardened Runtime disabled** — required for Accessibility APIs, Screen Capture Kit, and background process management

## Coordinate System

The vision model sees a downscaled 1280px-wide canvas. Mouse clicks are scaled back to physical Retina points using `CoordinateScaler`:

```
physicalX = modelX × (screenWidth / 1280)
physicalY = modelY × (screenHeight / captureHeight)
```

Use the **Test Coordinates** button on the dashboard to verify the transform is accurate on your display.

## License

Copyright © 2026 Daksh. All rights reserved.
