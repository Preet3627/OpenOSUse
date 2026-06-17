<div align="center">

# OpenOSUse

**An open-source, AI-native macOS automation agent with permission-gated OS control.**

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-cyan.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS_13%2B-blue)]()
[![Version](https://img.shields.io/badge/Version-0.2.9.4-blue)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)]()
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)]()
[![Built with ❤️](https://img.shields.io/badge/Built_With-%E2%9D%A4%EF%B8%8F-red)]()

[Features](#-features) • [Why OpenOSUse](#-why-openosuse) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Security](#-security) • [Contributing](#-contributing)

</div>

---

OpenOSUse lets a vision model observe your macOS screen and control your mouse and keyboard to automate any desktop task — opening apps, clicking buttons, typing text, navigating menus, and more. All OS interactions are permission-gated and fully transparent.

---

## ✨ Features

| Feature | Description |
|---|---|
| **👁️ Vision-Based Automation** | AI model watches your screen and decides what to click, type, or drag |
| **🖱️ Full OS Control** | Mouse clicks, keyboard input, key combos, app launching, menu navigation |
| **🔐 Permission-Gated Security** | Accessibility + Screen Recording permissions required; no silent control |
| **🤖 Multi-Provider AI** | Supports Anthropic Claude, Google Gemini, Groq, Grok (X.AI), and local Ollama |
| **📸 Real-Time Screen Capture** | ~30fps capture at 1280px width via SCStream |
| **🌳 Accessibility Tree** | Structured AX element readout — role, title, position, size, children — sent alongside screenshots |
| **🔌 MCP Protocol** | Model Context Protocol server (JSON-RPC 2.0 over TCP) for remote agent control |
| **🔄 5-State Agent Loop** | Capture → Plan → Execute → Observe → Cooldown with telemetry logging |
| **🔑 Keychain Secrets** | API keys stored in macOS Keychain — never in plaintext |
| **🎯 Coordinate Accuracy** | Vision coordinates auto-scaled to physical Retina points; built-in test tool |
| **⚡ Low-Latency Gateway** | TypeScript/Express + Vercel AI SDK routes requests to any provider |
| **📊 Telemetry Dashboard** | Live step-by-step agent log showing every decision and action |
| **🧪 Coordinate Test Tool** | One-click validation that model sees what you see |
| **🖥️ Lightweight** | Tested on i5-U / 8GB RAM — designed for low-spec hardware |

---

## 💡 Why OpenOSUse?

Most automation tools today are **closed-source**, **cloud-locked**, or **require programming knowledge**. OpenOSUse was built to change that:

- **AI-First** — Describe what you want in natural language; the AI figures out the steps
- **Privacy-First** — Choose your provider. Use local Ollama models for zero data leaving your machine
- **Permission-Gated** — Every OS-level action requires explicit system permissions granted via macOS Security & Privacy
- **Multi-Provider** — Not locked into any one AI vendor. Swap between Anthropic, Google, Groq, Grok, or Ollama freely
- **Transparent** — Every decision the AI makes is logged in the telemetry dashboard. No black boxes
- **Open Source** — Apache 2.0 licensed. Inspect, modify, and distribute freely
- **Beginner-Friendly** — No terminal scripting required. Native macOS app with a clean UI
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

Place the compiled `OpenOSUseGateway` binary in the Xcode target's Resources, or use `npm run dev` during development.

### 2. Build & Run the App

```bash
open OpenOSUse.xcodeproj
# Select scheme: OpenOSUse → Product → Run (⌘R)
```

On first launch the app will request **Accessibility** and **Screen Recording** permissions. Grant both in **System Settings → Privacy & Security**.

### 3. Configure an API Key

Use the in-app UI or the command line to store a provider key in the Keychain:

```swift
KeychainManager.shared.saveProviderKey(provider: "anthropic", key: "sk-ant-...")
```

### 4. Run an Agent

1. Type an objective (e.g. *"Open Safari and go to github.com"*)
2. Click **Go**
3. Watch the agent work — the telemetry log shows every step: capture, plan, execute, cooldown

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
├── OpenOSUse.xcodeproj/              # Xcode project
├── OpenOSUse/
│   ├── OpenOSUseApp.swift            # @main entry point
│   ├── ContentView.swift             # Dashboard UI (Liquid Glass redesign)
│   ├── PermissionManager.swift       # Accessibility + Screen Recording
│   ├── ScreenCaptureEngine.swift     # SCStream capture (~30fps, 1280px)
│   ├── AXElementReader.swift         # Accessibility Tree snapshot
│   ├── SystemAutomationEngine.swift  # Mouse, keyboard, app launch, scaling
│   ├── AgentOrchestrationLoop.swift  # 5-state agent loop + AX Tree support
│   ├── MCPServer.swift               # Model Context Protocol server
│   ├── GatewayBinaryHost.swift       # Child process management
│   ├── KeychainManager.swift         # Secure API key storage
│   ├── CoordinateAccuracyTest.swift  # Coordinate transform validation
│   ├── Info.plist
│   └── OpenOSUse.entitlements
├── server/
│   ├── server.ts                     # Express + Vercel AI SDK gateway
│   ├── package.json
│   ├── tsconfig.json
│   ├── test_providers.sh
│   └── .env.example
├── CHANGELOG.md                      # Release history
├── release-notes/                    # Per-version release notes
│   └── v0.1.1.md
└── .github/workflows/
    └── release.yml                   # Tag-triggered build + release
```

---

## 📖 Documentation

Full component documentation is available on the [docs site](https://open-os-use-docs.vercel.app/) or locally in the [`Docs/`](Docs/) directory:

| Page | Description |
|---|---|
| [Landing Page](Docs/index.md) | Architecture overview, data flow, security model |
| [ARCHITECTURE](Docs/ARCHITECTURE.md) | Layered architecture diagram and design decisions |
| [OpenOSUseApp](Docs/components/OpenOSUseApp.md) | App entry point and lifecycle |
| [ContentView](Docs/components/ContentView.md) | Dashboard UI layout and states |
| [PermissionManager](Docs/components/PermissionManager.md) | Permission handling |
| [ScreenCaptureEngine](Docs/components/ScreenCaptureEngine.md) | Screen capture internals |
| [SystemAutomationEngine](Docs/components/SystemAutomationEngine.md) | Mouse/keyboard automation |
| [AgentOrchestrationLoop](Docs/components/AgentOrchestrationLoop.md) | Agent loop state machine |
| [AXElementReader](Docs/components/AXElementReader.md) | Accessibility Tree integration |
| [MCPServer](Docs/components/MCPServer.md) | MCP protocol server |
| [KeychainManager](Docs/components/KeychainManager.md) | Keychain storage API |
| [CoordinateAccuracyTest](Docs/components/CoordinateAccuracyTest.md) | Coordinate transform testing |
| [GatewayBinaryHost](Docs/components/GatewayBinaryHost.md) | Child process lifecycle |
| [Gateway Server](Docs/server/gateway.md) | TypeScript server and provider routing |
| [Server Configuration](Docs/server/configuration.md) | package.json, tsconfig, scripts |

---

## 🔒 Security

- **API keys stored in macOS Keychain** — never in plain-text files or configs
- **Header-based key injection** — keys travel via `X-Provider-API-Key` header, never via environment variables or request body
- **Empty process environment** — the gateway binary runs with `process.environment = [:]` to eliminate terminal/shell dependency
- **App Sandbox + Hardened Runtime disabled** — required for Accessibility APIs, Screen Capture Kit, and background process management
- **Permission-gated** — no OS action happens without explicit user-granted permissions
- **Full telemetry** — every AI decision and action is logged to the dashboard

---

## 📐 Coordinate System

The vision model sees a downscaled 1280px-wide canvas. Mouse clicks are scaled back to physical Retina points using `CoordinateScaler`:

```
physicalX = modelX × (screenWidth / 1280)
physicalY = modelY × (screenHeight / captureHeight)
```

Use the **Test Coordinates** button on the dashboard to verify the transform is accurate on your display.

---

## 🤝 Contributing

Contributions are welcome! Open an issue or submit a PR.

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code follows existing patterns and passes any linting/type checks.

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
