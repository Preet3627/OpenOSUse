# KeychainManager.swift

**Path:** `OpenOSUse/OpenOSUse/KeychainManager.swift`

A singleton wrapper around the macOS Security framework (`Security.framework`) for storing and retrieving provider API keys.

## Service Identifier

All keys are stored under the service name `com.daksh.OpenOSUse.apiKeys` with the account name set to the provider name (e.g. `"anthropic"`, `"google"`, `"groq"`, `"grok"`, `"ollama"`).

## Methods

| Method | Returns | Behaviour |
|---|---|---|
| `saveProviderKey(provider:key:)` | `Bool` | Saves or updates a key. If the item already exists (`errSecDuplicateItem`), it calls `SecItemUpdate` instead |
| `getProviderKey(provider:)` | `String?` | Retrieves a key by provider name |
| `deleteProviderKey(provider:)` | `Bool` | Deletes a key, returning `true` if successful or if the item didn't exist |

## Security Properties

- **Accessible after first unlock** — `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` means the keychain item persists across reboots but is not migrated to other devices
- **No plain-text storage** — keys are never written to `.env` files, `UserDefaults`, or the filesystem
- **Per-request injection** — `AgentOrchestrationLoop` reads the key from the Keychain on every POST and injects it as an HTTP header, so a single compromised read doesn't leak the key

## Usage

```swift
// Save
KeychainManager.shared.saveProviderKey(provider: "anthropic", key: "sk-ant-...")

// Read
let key = KeychainManager.shared.getProviderKey(provider: "anthropic")

// Delete
KeychainManager.shared.deleteProviderKey(provider: "anthropic")
```
