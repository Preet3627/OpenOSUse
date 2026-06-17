# AgentSettings.swift

**Path:** `OpenOSUse/OpenOSUse/AgentSettings.swift`

A `@MainActor` ObservableObject singleton that manages all user-configurable settings with automatic persistence via `UserDefaults`.

## Published Properties

### Provider & Models

| Property | Type | Default | Description |
|---|---|---|---|
| `provider` | `String` | `"anthropic"` | Active AI provider key |
| `modelName` | `String` | `"claude-3-5-sonnet-20241022"` | Chat/reasoning model name |
| `visionModelName` | `String` | same as `modelName` | Vision model for screenshot description |
| `availableModels` | `[String]` | `[]` | Models fetched from provider API |
| `isLoadingModels` | `Bool` | `false` | Loading state for model fetch |
| `modelFetchError` | `String?` | `nil` | Error message from last model fetch |

### Server

| Property | Type | Default | Description |
|---|---|---|---|
| `serverURLString` | `String` | `"http://localhost:3000/api/agent/step"` | Gateway server endpoint |

### Tuning

| Property | Type | Default | Description |
|---|---|---|---|
| `coolDownMs` | `Double` | `500` | Pause between agent steps |
| `maxRetries` | `Int` | `3` | Retry attempts on server failure |
| `requestTimeout` | `Double` | `30` | HTTP request timeout in seconds |

### Feature Toggles

| Property | Type | Default | Description |
|---|---|---|---|
| `useAXTree` | `Bool` | `false` | Capture Accessibility Tree alongside screenshots |
| `showNotifications` | `Bool` | `true` | macOS notifications on agent finish/error |
| `useScreenshot` | `Bool` | `true` | Capture screen for visual context |
| `useVisionModel` | `Bool` | `true` | Use separate vision model to describe screenshots |

### Computed

| Property | Description |
|---|---|
| `serverURL` | Parsed `URL` from `serverURLString` |
| `supportedVisionModels` | Filters `availableModels` to known vision-capable models |

## Methods

### `fetchModels()`
Calls `ModelFetcher.fetchModels(provider:apiKey:)` for the current provider. Updates `availableModels`, `isLoadingModels`, and `modelFetchError`.

### `applyToOrchestrator()`
Copies all current settings into `AgentOrchestrationLoop.shared` so the next agent session uses them.

## Model Fetching

Each provider has a dedicated API endpoint:

| Provider | Endpoint | Auth |
|---|---|---|
| Ollama | `GET {baseURL}/api/tags` | None (uses server URL) |
| Gemini | `GET /v1/models?key={key}` | Query param |
| Anthropic | `GET /v1/models` | `x-api-key` header |
| Groq | `GET /v1/models` | `Bearer` token |
| Grok | `GET /v1/models` | `Bearer` token |

## Vision Model Filtering

`supportedVisionModels` applies per-provider heuristics:
- **Anthropic, Gemini**: all models support vision → include all
- **Ollama**: models containing `llava`, `bakllava`, `moondream`, `vision`, `pixtral`
- **Groq**: models containing `llava`, `pixtral`, `vision`, plus exact matches for `llama-3.2-11b-vision-preview` and `llama-3.2-90b-vision-preview`
- **Grok**: models containing `vision`
