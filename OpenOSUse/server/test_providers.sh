#!/usr/bin/env bash
# ==========================================================================
# test_providers.sh
#
# Smoke-test every supported AI provider against the local agent server.
# Pass API keys via environment variables (see .env.example).
#
# Usage:
#   export ANTHROPIC_API_KEY="sk-..."
#   export OPENAI_API_KEY="sk-..."
#   export GOOGLE_API_KEY="..."
#   export GROQ_API_KEY="gsk_..."
#   export GROK_API_KEY="xai-..."
#   bash test_providers.sh
# ==========================================================================

set -euo pipefail

BASE_URL="${AGENT_URL:-http://localhost:3000/api/agent/step}"

# Generate a tiny valid JPEG (1×1 grey pixel) as the dummy screenshot.
# We embed it raw so cURL sends a proper data URL.
DUMMY_B64="$(echo -n '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19i5usLDxMXGx8jJytLT1NXW19jZ+foLHSUlJSEhISEhISEhISEhISEhISEhISEhI//Z' | base64)"

PASS=0
FAIL=0

# Each test case: "provider" "modelName" ["env_var"]
TESTS=(
  "ollama    llama3.2-vision     -"
  "anthropic claude-3-5-sonnet-20241022 ANTHROPIC_API_KEY"
  "google    gemini-2.5-flash    GOOGLE_API_KEY"
  "groq      llama-3.3-70b-versatile GROQ_API_KEY"
  "grok      grok-2              GROK_API_KEY"
)

run_test() {
  local provider="$1" model="$2" key_var="$3" api_key body status tool

  # Resolve API key
  api_key="${!key_var:-}"
  if [[ "$provider" != "ollama"" && -z "$api_key" ]]; then
    echo "  ⚠ SKIP  –  $key_var not set"
    return 2
  fi

  body="$(
    cat <<JSON
{
  "provider": "$provider",
  "modelName": "$model",
  "apiKey": "${api_key:-null}",
  "screenshot": "$DUMMY_B64",
  "objective": "Return the current mouse cursor position as a tool call.",
  "history": []
}
JSON
  )"

  status="$(curl -s -o /dev/null -w '%{http_code}' \
    -X POST "$BASE_URL" \
    -H 'Content-Type: application/json' \
    -d "$body" 2>/dev/null)"

  if [[ "$status" == "200" ]]; then
    echo "  ✅ $provider ($model)  →  HTTP $status"
    return 0
  else
    echo "  ❌ $provider ($model)  →  HTTP $status"
    return 1
  fi
}

# --------------------------------------------------------------------------
echo "══════════════════════════════════════════════════════"
echo " API Router Isolation – Provider Smoke Tests"
echo " Target: $BASE_URL"
echo "══════════════════════════════════════════════════════"
echo ""

for spec in "${TESTS[@]}"; do
  read -r provider model key_var <<< "$spec"
  printf "  ▶  %-10s %-30s … " "$provider" "$model"
  run_test "$provider" "$model" "$key_var"
  case $? in
    0) ((PASS++)) ;;
    1) ((FAIL++)) ;;
    2) ;;
  esac
done

# --------------------------------------------------------------------------
echo ""
echo "──────────────────────────────────────────────────────"
echo " Results:  $PASS passed,  $FAIL failed"
echo "──────────────────────────────────────────────────────"

# Return exit code matching failure count so CI can honour it.
exit "$FAIL"
