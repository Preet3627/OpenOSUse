# MCPServer

The `MCPServer` singleton implements the **Model Context Protocol** (MCP) over TCP, allowing remote clients to drive the OpenOSUse agent programmatically.

## Overview

- **Protocol**: JSON-RPC 2.0 over TCP
- **Default Port**: 8081
- **Service Discovery**: Bonjour (`_mcp._tcp`)
- **Thread Safety**: All state is managed on `@MainActor`

## Methods

### `initialize`

Returns the server capabilities and available tools.

### `execute_tool`

Invokes an agent tool. Supported tools:

| Tool | Parameters | Description |
|---|---|---|
| `screenshot` | none | Captures the current screen as base64 JPEG |
| `axTree` | `maxDepth` (optional) | Reads the Accessibility tree of the frontmost app |
| `click` | `x`, `y` | Clicks at screen coordinates |
| `type` | `text` | Types text at current focus |
| `open_app` | `bundleId` | Opens an application |

### `shutdown`

Gracefully disconnects the client.

## Response Format

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tool": "screenshot",
    "arguments": { "data": "base64..." },
    "thinking": null,
    "nextStep": null
  }
}
```

## Usage

Toggle the MCP server on/off from the **MCP Server** tab in the dashboard. The server starts automatically when enabled and listens for JSON-RPC connections on the configured port.
