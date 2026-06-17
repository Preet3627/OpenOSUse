# OpenOSUse Gateway Server

**Path:** `server/server.ts`

The TypeScript backend that receives screenshots from the Swift app, routes them to the configured AI provider, and returns structured tool-call responses.

## Tech Stack

- **Runtime:** Node.js (compiled to standalone binary via `pkg` or similar)
- **Framework:** Express
- **AI SDK:** Vercel AI SDK (`ai`) with provider packages:
  - `@ai-sdk/openai` — OpenAI-compatible providers (Groq, Grok/X.AI)
  - `@ai-sdk/anthropic` — Anthropic Claude
  - `@ai-sdk/google` — Google Gemini
  - `ollama-ai-provider` — Local Ollama models
- **Validation:** Zod (used for tool parameter schemas)

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
  "screenshot": "<base64-encoded JPEG data>",
  "objective": "Open Safari and navigate to GitHub",
  "history": []
}
```

#### Response

```json
{
  "tool": "click",
  "arguments": { "x": 640, "y": 480 },
  "thinking": "The Safari icon is at the center of the dock..."
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

## Tools

The LLM chooses exactly one tool per step via `toolChoice: "required"`:

| Tool | Parameters | Description |
|---|---|---|
| `open_app` | `bundleId: string` | Open/focus a macOS app by bundle identifier |
| `click` | `x: number, y: number` | Click at screen coordinates (points, top-left origin) |
| `type` | `text: string` | Type text at current cursor position |
| `key_combo` | `keys: string[]` | Press a keyboard shortcut |
| `wait` | `durationMs: number` | Pause execution |
| `finish` | `summary: string` | Signal objective complete |

## Security

- API keys arrive **exclusively** via the `X-Provider-API-Key` header — the server never reads `process.env.*_API_KEY`
- The only environment variable read is `OLLAMA_BASE_URL` (a local network address, not a secret)
- If the key header is missing and the provider is not Ollama, the server returns HTTP 401
- Request body is limited to 100MB to accommodate large base64 screenshots

## Development

```bash
cd server
npm install
npm run dev       # tsx watch server.ts  (hot-reload)
npm run build     # tsc
npm run typecheck # tsc --noEmit
```
