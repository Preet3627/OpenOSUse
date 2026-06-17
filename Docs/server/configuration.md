# Server Configuration

## package.json

**Path:** `server/package.json`

| Field | Value |
|---|---|
| Name | `openosuse-server` |
| Type | `module` (ESM) |
| Build tool | `tsc` + `tsx` for development |

### Scripts

| Script | Command | Purpose |
|---|---|---|
| `dev` | `tsx watch server.ts` | Development with hot-reload |
| `start` | `tsx server.ts` | Production run via tsx |
| `build` | `tsc` | Compile TypeScript to `dist/` |
| `typecheck` | `tsc --noEmit` | Type-check without emitting files |

### Dependencies

| Package | Version | Purpose |
|---|---|---|
| `ai` | ^4.2.0 | Vercel AI SDK core |
| `@ai-sdk/openai` | ^1.2.0 | OpenAI-compatible provider |
| `@ai-sdk/anthropic` | ^1.2.0 | Anthropic Claude provider |
| `@ai-sdk/google` | ^1.2.0 | Google Gemini provider |
| `ollama-ai-provider` | ^1.2.0 | Local Ollama provider |
| `express` | ^4.21.2 | HTTP server |
| `cors` | ^2.8.5 | CORS middleware |
| `zod` | ^3.24.0 | Schema validation |

## tsconfig.json

**Path:** `server/tsconfig.json`

- Target: ES2022
- Module: ESNext (bundler resolution)
- Output: `dist/`
- Strict mode enabled
- `skipLibCheck: true` for faster builds

## .gitignore

**Path:** `server/.gitignore`

Ignores: `node_modules/`, `dist/`, `.env`, `*.tsbuildinfo`

## .env.example

**Path:** `server/.env.example`

Documents the expected environment variables (for reference only — actual API keys are now sent via HTTP headers):

```env
# At least one of these must be set (or pass apiKey per request)
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GOOGLE_API_KEY=
GROQ_API_KEY=
GROK_API_KEY=

# Ollama runs locally — no key needed
OLLAMA_BASE_URL=http://localhost:11434
```

## test_providers.sh

**Path:** `server/test_providers.sh`

A smoke-test script that sends a dummy screenshot to every supported provider and reports HTTP status codes.

### Usage

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export GROQ_API_KEY="gsk_..."
# ... etc
bash test_providers.sh
```

**Note:** This test script was written before the switch to header-based API keys and still embeds keys in the JSON body. It will need updating to use the `X-Provider-API-Key` header pattern.
