# AXElementReader

The `AXElementReader` singleton uses the macOS Accessibility API (`ApplicationServices` / `AXUIElement`) to snapshot the element tree of the frontmost application and return it as structured JSON.

## Overview

- **Role**: Reads the Accessibility element hierarchy of the active application
- **Permission**: Requires Accessibility access (`AXIsProcessTrusted()`)
- **Output**: Nested JSON with role, title, description, value, focus state, position, size, and children

## API

### `readFrontmostAppTree(maxDepth:) -> AXNode`

Returns the root `AXNode` of the frontmost app's element tree.

### `readFrontmostAppTreeJSON(maxDepth:) -> String`

Returns the tree as a JSON string (or `{"error": "..."}` on failure).

### `AXNode`

| Field | Type | Description |
|---|---|---|
| `role` | String | AX role (e.g. `AXButton`, `AXTextField`, `AXWindow`) |
| `title` | String | Element title/label |
| `description` | String | Accessibility description |
| `value` | String | Current value (e.g. text field contents, slider value) |
| `isFocused` | Bool | Whether the element currently has focus |
| `frame` | `{x, y, width, height}` | Screen position in physical pixels |
| `children` | [AXNode] | Child elements in the hierarchy |

## Usage in Agent Loop

When `AgentOrchestrationLoop.useAXTree` is `true`, the loop captures the AX tree alongside the screenshot and sends it in the `StepRequest.axTree` field to the gateway server. This gives the AI model structured UI context in addition to pixel data.

## Security

Only available when the process has Accessibility permission. The `PermissionManager` handles requesting this permission.
