<div align="center">

# OpenOSUse

**An open-source, AI-native macOS automation agent with permission-gated OS control.**

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-cyan.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS_13%2B-blue)]()
[![Version](https://img.shields.io/badge/Version-2.1.0-blue)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)]()
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)]()
[![Built with ❤️](https://img.shields.io/badge/Built_With-%E2%9D%A4%EF%B8%8F-red)]()

[Features](#-features) • [Why OpenOSUse](#-why-openosuse) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Security](#-security) • [Contributing](#-contributing)

</div>

---

OpenOSUse lets an AI agent observe and control your macOS desktop — opening apps, clicking buttons, typing text, navigating menus, and more. All OS interactions are permission-gated, Touch ID-verified, and fully transparent.

---

## ✨ Features

| Feature | Description |
|---|---|
| **👁️ Vision-Based Automation** | AI model watches your screen and decides what to click, type, or drag |
| **🖱️ Native AX Element Clicking** | `click_element` uses macOS Accessibility API to find and click UI elements by label — no vision needed, works at any resolution |
| **🔐 Touch ID Verification** | Every chat session requires biometric authentication before the first click executes |
| **🖥️ Full OS Control** | Mouse clicks, keyboard input, key combos, app launching, AX element targeting |
| **🔒 Permission-Gated Security** | Accessibility + Screen Recording permissions required; no silent control |
| **🤖 Multi-Provider AI** | Anthropic Claude, Google Gemini, Groq, Grok (X.AI), and local Ollama |
| **📸 Optional Screenshots** | Toggle screen capture on/off. When off, agent uses AX tree only — no Screen Recording permission needed |
| **👁️ Optional Vision Model** | Toggle separate vision model on/off. Two-step pipeline (vision describes → chat reasons) when both are active |
| **🔄 Auto-Fetch Models** | Dropdown populated from provider's model list API, with manual refresh |
| **🔀 Dual Model Selection** | Separate dropdowns for chat/reasoning model and vision model |
| **🌳 Accessibility Tree** | Structured AX element readout sent alongside screenshots for richer context |
| **🔌 MCP Protocol** | Model Context Protocol server (JSON-RPC 2.0) for remote agent control |
| **🔄 5-State Agent Loop** | Observe → Plan → Execute → Cooldown → Repeat with full telemetry |
| **🔑 Keychain Secrets** | API keys stored in macOS Keychain — never in plaintext |
| **📊 Telemetry Dashboard** | Live step-by-step agent log with export to JSON |
| **⚡ Low-Latency Gateway** | TypeScript/Express + Vercel AI SDK routes requests to any provider |

---

## 💡 Why OpenOSUse?

Most automation tools are **closed-source**, **cloud-locked**, or **require programming knowledge**. OpenOSUse was built to change that:

- **AI-First** — Describe what you want in natural language; the AI figures out the steps
- **Privacy-First** — Choose your provider. Use local Ollama models for zero data leaving your machine
- **Permission-Gated** — Every OS-level action requires explicit system permissions granted via macOS Security & Privacy
- **Touch ID-Protected** — No click happens without biometric authorization
- **Multi-Provider** — Not locked into any one AI vendor. Swap between Anthropic, Google, Groq, Grok, or Ollama freely
- **Transparent** — Every decision the AI makes is logged in the telemetry dashboard
- **Open Source** — Apache 2.0 licensed. Inspect, modify, and distribute freely
- **Low-Spec Ready** — Optimized to run on older hardware (tested on i5-U / 8GB RAM)

---

## 🚀 Quick Start

### Prerequisites

- macOS 13.0+ (Ventura)
- Xcode 16+
- Node.js 20+
- An API key for at least one supported provider

### 1. Build the Gateway Server

```bash
cd OpenOSUse/server
npm install
npm run build
```

### 2. Build & Run the App

```bash
open OpenOSUse.xcodeproj
# Select scheme: OpenOSUse → Product → Run (⌘R)
```

On first launch the app will request **Accessibility** and (if screenshot is enabled) **Screen Recording** permissions.

### 3. Configure an API Key

Use the in-app Settings tab or the command line:

```swift
KeychainManager.shared.saveProviderKey(provider: "anthropic", key: "sk-ant-...")
```

### 4. Run an Agent

1. Type an objective (e.g. *"Open Safari and go to github.com"*)
2. Click **Launch Agent**
3. Approve Touch ID when prompted (first click only)
4. Watch the agent work in the telemetry log

---

## 🤖 Supported AI Providers

| Provider | Model Example | Key Needed |
|---|---|---|
| **Anthropic** | `claude-3-5-sonnet-20241022` | Yes |
| **Google** | `gemini-2.5-flash` | Yes |
| **Groq** | `llama-3.3-70b-versatile` | Yes |
| **Grok (X.AI)** | `grok-2` | Yes |
| **Ollama** | `llama3.2-vision` | No (local) |

---

## 📂 Project Structure

```
OpenOSUse/
├── OpenOSUse.xcodeproj/               # Xcode project
├── OpenOSUse/
│   ├── OpenOSUseApp.swift             # @main entry point
│   ├── ContentView.swift              # Dashboard UI with Settings tab
│   ├── AgentSettings.swift            # UserDefaults-backed config + model fetching
│   ├── PermissionManager.swift        # Accessibility + Screen Recording
│   ├── ScreenCaptureEngine.swift      # SCStream capture (~30fps, 1280px)
│   ├── AXElementReader.swift          # Accessibility Tree snapshot
│   ├── ModelFetcher.swift             # Provider-specific model list APIs
│   ├── SystemAutomationEngine.swift   # Mouse, keyboard, AX element clicking, scaling
│   ├── AgentOrchestrationLoop.swift   # 5-state agent loop + Touch ID + conditional pipeline
│   ├── MCPServer.swift                # Model Context Protocol server
│   ├── GatewayBinaryHost.swift        # Child process management
│   ├── KeychainManager.swift          # Secure API key storage
│   ├── CoordinateAccuracyTest.swift   # Coordinate transform validation
│   ├── Info.plist
│   └── OpenOSUse.entitlements
├── server/
│   ├── server.ts                      # Express + Vercel AI SDK gateway
│   ├── package.json
│   ├── tsconfig.json
│   └── .env.example
├── Docs/                              # Full documentation site (Next.js)
│   ├── index.md                       # Architecture overview
│   ├── components/                    # Per-component docs
│   └── server/                        # Gateway server docs
├── CHANGELOG.md
├── release-notes/
└── .github/workflows/
    └── release.yml
```

---

## 📖 Documentation

Full documentation is available in the [`Docs/`](Docs/) directory:

### Components

| Component | File | Purpose |
|---|---|---|
| [App Entry Point](Docs/components/OpenOSUseApp.md) | `OpenOSUseApp.swift` | App lifecycle, gateway launch |
| [Dashboard UI](Docs/components/ContentView.md) | `ContentView.swift` | All UI tabs, settings, telemetry |
| [Agent Settings](Docs/components/AgentSettings.md) | `AgentSettings.swift` | Config persistence, model fetching, dual model selection |
| [Permission Manager](Docs/components/PermissionManager.md) | `PermissionManager.swift` | Permission requests and monitoring |
| [Screen Capture](Docs/components/ScreenCaptureEngine.md) | `ScreenCaptureEngine.swift` | Screen capture engine |
| [System Automation](Docs/components/SystemAutomationEngine.md) | `SystemAutomationEngine.swift` | Mouse, keyboard, AX element clicking, scaling |
| [Agent Loop](Docs/components/AgentOrchestrationLoop.md) | `AgentOrchestrationLoop.swift` | State machine, conditional pipeline, Touch ID |
| [AX Reader](Docs/components/AXElementReader.md) | `AXElementReader.swift` | Accessibility tree parsing |
| [Model Fetcher](Docs/components/ModelFetcher.md) | `ModelFetcher.swift` | Provider model list APIs |
| [MCP Server](Docs/components/MCPServer.md) | `MCPServer.swift` | Remote agent control protocol |
| [Keychain Manager](Docs/components/KeychainManager.md) | `KeychainManager.swift` | Secure key storage |
| [Gateway Host](Docs/components/GatewayBinaryHost.md) | `GatewayBinaryHost.swift` | Child process management |

### Server

| Document | File | Purpose |
|---|---|---|
| [Gateway Server](Docs/server/gateway.md) | `server.ts` | Express app, provider routing, tools |
| [Configuration](Docs/server/configuration.md) | `package.json` etc. | Build and dev configuration |

---

## 🔒 Security

- **API keys in Keychain** — never in plain-text files or configs
- **Header-based key injection** — keys travel via `X-Provider-API-Key` header
- **Touch ID verification** — every agent session requires biometric authentication before the first click
- **Permission-gated** — no OS action without explicit user-granted permissions (Accessibility, Screen Recording)
- **Optional screenshots** — toggle off to avoid Screen Recording permission entirely
- **Full telemetry** — every AI decision and action is logged

---

## 📐 Coordinate System

When screenshot mode is enabled, the vision model sees a downscaled 1280px-wide canvas. Mouse clicks are scaled back to physical Retina points:

```
physicalX = modelX × (screenWidth / 1280)
physicalY = modelY × (screenHeight / captureHeight)
```

**Prefer `click_element`** over `click(x,y)` — it uses the Accessibility API to find elements by label, so it works at any resolution without coordinate scaling.

---

## 🤝 Contributing

Contributions are welcome! Open an issue or submit a PR.

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

Copyright © 2026 Daksh

Licensed under the **Apache License, Version 2.0** (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
