# ModelFetcher.swift

**Path:** `OpenOSUse/OpenOSUse/ModelFetcher.swift`

A utility struct with static async methods that query each AI provider's API for available models. Used by `AgentSettings.fetchModels()` to populate the model picker dropdowns.

## Methods

### `fetchModels(provider:apiKey:) -> [String]`
Routes to the correct provider-specific fetcher based on the provider string.

| Provider | Fetcher | API |
|---|---|---|
| `ollama` | `fetchOllama(baseURL:)` | `GET /api/tags` |
| `google` | `fetchGemini(apiKey:)` | `GET /v1/models?key={key}` |
| `anthropic` | `fetchAnthropic(apiKey:)` | `GET /v1/models` |
| `groq` | `fetchGroq(apiKey:)` | `GET /v1/models` |
| `grok` | `fetchGrok(apiKey:)` | `GET /v1/models` |

### `isVisionModel(_:provider:) -> Bool`
Determines whether a model name is vision-capable based on provider-specific heuristics:

| Provider | Heuristic |
|---|---|
| `anthropic`, `google` | All models are vision-capable |
| `ollama` | Name contains `llava`, `bakllava`, `moondream`, `vision`, or `pixtral` |
| `groq` | Name contains `llava`, `pixtral`, or `vision`; or exact match `llama-3.2-11b-vision-preview` / `llama-3.2-90b-vision-preview` |
| `grok` | Name contains `vision` |

## Response Parsing

Each fetcher parses the provider-specific JSON response format and extracts model ID strings:

- **Ollama**: `{ "models": [{ "name": "llama3.2-vision:latest" }] }`
- **Gemini**: `{ "models": [{ "name": "models/gemini-2.0-flash", "supportedGenerationMethods": ["generateContent"] }] }` (filters for `generateContent` support)
- **Anthropic**: `{ "data": [{ "id": "claude-3-5-sonnet-20241022" }] }`
- **Groq/Grok**: `{ "data": [{ "id": "llama-3.3-70b-versatile" }] }`
