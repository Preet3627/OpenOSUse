# OpenOSUse Gateway Server

**Path:** `server/server.ts`

The TypeScript backend that receives context from the Swift app, routes to AI providers, and returns structured tool-call responses.

## Tech Stack

- **Runtime:** Node.js (compiled via `tsc`)
- **Framework:** Express
- **AI SDK:** Vercel AI SDK (`ai`) with provider packages:
  - `@ai-sdk/openai` — OpenAI-compatible (Groq, Grok/X.AI)
  - `@ai-sdk/anthropic` — Anthropic Claude
  - `@ai-sdk/google` — Google Gemini
  - `ollama-ai-provider` — Local Ollama
- **Validation:** Zod

## API

### `POST /api/agent/step`

#### Headers

| Header | Required | Description |
|---|---|---|
| `X-Target-Provider` | Yes | One of: `ollama`, `anthropic`, `google`, `groq`, `grok` |
| `X-Provider-API-Key` | Yes (except Ollama) | The API key for the chosen provider |

#### Body

```json
{
  "modelName": "claude-3-5-sonnet-20241022",
  "visionModelName": "claude-3-5-haiku-20241017",
  "screenshot": "<base64 JPEG, optional>",
  "objective": "Open Safari and navigate to GitHub",
  "history": []
}
```

- `screenshot` is optional — when omitted the model receives only text context
- `visionModelName` is optional — when provided and differs from `modelName`, a two-step pipeline is used

#### Response

```json
{
  "tool": "click_element",
  "arguments": { "label": "Save", "role": "AXButton" },
  "thinking": "The Save button is visible in the toolbar..."
}
```

## Provider Routing

```
x-target-provider: anthropic   →  createAnthropic({ apiKey })(modelName)
x-target-provider: google      →  createGoogleGenerativeAI({ apiKey })(modelName)
x-target-provider: groq        →  createOpenAI({ apiKey, baseURL: "https://api.groq.com/openai/v1" }).chat(modelName)
x-target-provider: grok        →  createOpenAI({ apiKey, baseURL: "https://api.x.ai/v1" }).chat(modelName)
x-target-provider: ollama      →  createOllama({ baseURL: process.env.OLLAMA_BASE_URL || "http://localhost:11434" }).chat(modelName)
```

## Two-Step Vision Pipeline

When both `screenshot` and `visionModelName` (different from `modelName`) are provided:

1. **Vision step** — sends screenshot to `visionModelName` with a "describe this screenshot" prompt → receives text description
2. **Chat step** — sends the text description (no image) + system prompt + history to `modelName` → receives tool call

When `visionModelName` matches `modelName` or is omitted, the screenshot is sent directly to the chat model (single step).

When no screenshot is provided, only text context (objective + history) is sent to the chat model.

## Tools

The LLM chooses exactly one tool per step via `toolChoice: "required"`:

| Tool | Parameters | Description |
|---|---|---|
| `click_element` | `label: string, role?: string` | Click a UI element by its on-screen label. Uses macOS Accessibility API. **Preferred over click(x,y)** |
| `click` | `x: number, y: number` | Click at screen coordinates. Use only when the target has no visible label |
| `open_app` | `bundleId: string` | Open/focus a macOS app by bundle identifier |
| `type` | `text: string` | Type text at current cursor position |
| `key_combo` | `keys: string[]` | Press a keyboard shortcut |
| `wait` | `durationMs: number` | Pause execution |
| `finish` | `summary: string` | Signal objective complete |

## System Prompt

The prompt instructs the model to:
- Prefer `click_element` over `click` when the target has a visible label
- Use AX element labels (e.g. `click_element("Save", "AXButton")`) for robust cross-resolution targeting
- Call one tool per step
- Call `finish` only when the objective is fully achieved

## Security

- API keys arrive **exclusively** via the `X-Provider-API-Key` header — never in `process.env`
- The only environment variable read is `OLLAMA_BASE_URL` (a local network address, not a secret)
- Missing key header for non-Ollama providers → HTTP 401
- Request body limit: 100MB

## Development

```bash
cd server
npm install
npm run dev       # tsx watch server.ts  (hot-reload)
npm run build     # tsc
npm run typecheck # tsc --noEmit
```
