import express from "express";
import cors from "cors";
import { generateText, tool } from "ai";
import { createOpenAI } from "@ai-sdk/openai";
import { createAnthropic } from "@ai-sdk/anthropic";
import { createGoogleGenerativeAI } from "@ai-sdk/google";
import { createOllama } from "ollama-ai-provider";
import { z } from "zod";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface StepRequest {
  modelName: string;
  screenshot: string;
  objective: string;
  history: ActionEntry[];
}

interface ActionEntry {
  role: "assistant" | "tool";
  tool: string;
  arguments: Record<string, unknown>;
  result?: string;
}

interface StepResponse {
  tool: string;
  arguments: Record<string, unknown>;
  thinking: string | null;
}

// ---------------------------------------------------------------------------
// Tool definitions (Vercel AI SDK `tool()` wrappers)
// ---------------------------------------------------------------------------

const computerTools = {
  open_app: tool({
    description:
      "Open or focus a macOS application by its bundle identifier. " +
      'Examples: "com.apple.Safari", "com.microsoft.VSCode", "com.apple.finder".',
    parameters: z.object({
      bundleId: z
        .string()
        .describe(
          "macOS bundle identifier of the application to open or focus"
        ),
    }),
  }),

  click: tool({
    description:
      "Click at specific screen coordinates (points, top-left origin).",
    parameters: z.object({
      x: z.number().describe("x-coordinate in screen points"),
      y: z.number().describe("y-coordinate in screen points"),
    }),
  }),

  type: tool({
    description: "Type a string of text at the current cursor location.",
    parameters: z.object({
      text: z.string().describe("The exact text to type"),
    }),
  }),

  key_combo: tool({
    description:
      "Press a keyboard shortcut / key combination. " +
      'Examples: ["cmd", "space"], ["cmd", "c"], ["ctrl", "shift", "escape"].',
    parameters: z.object({
      keys: z
        .array(z.string())
        .describe("Key names to press together (e.g. cmd, shift, c)"),
    }),
  }),

  wait: tool({
    description:
      "Wait / pause execution for a given duration. Use this after launching " +
      "apps or before clicking on elements that may not be immediately visible.",
    parameters: z.object({
      durationMs: z
        .number()
        .describe("Duration to wait in milliseconds"),
    }),
  }),

  finish: tool({
    description:
      "Call this when the user's objective has been completed or if you " +
      "cannot proceed further.",
    parameters: z.object({
      summary: z
        .string()
        .describe("Brief summary of what was accomplished"),
    }),
  }),
};

// ---------------------------------------------------------------------------
// System prompt builder
// ---------------------------------------------------------------------------
// System prompt builder
// ---------------------------------------------------------------------------

function buildSystemPrompt(objective: string, history: ActionEntry[]): string {
  const historyBlock =
    history.length > 0
      ? `\nPrevious actions taken this session:\n${history
          .map(
            (h, i) =>
              `  ${i + 1}. ${h.tool}(${JSON.stringify(h.arguments)}) → ${h.result ?? "pending"}`
          )
          .join("\n")}\n`
      : "";

  return [
    `You are an AI computer-use agent controlling a macOS machine.`,
    ``,
    `## Objective`,
    objective,
    historyBlock,
    ``,
    `## Available tools (choose exactly ONE per step)`,
    ``,
    `- **open_app** — "Open or focus a macOS application. Requires bundleId."`,
    `- **click** — "Click at screen coordinates (points, top-left origin)."`,
    `- **type** — "Type text at the current cursor position."`,
    `- **key_combo** — "Press a keyboard shortcut (e.g. cmd+space)."`,
    `- **wait** — "Pause for durationMs milliseconds."`,
    `- **finish** — "Call ONLY when the objective is fully complete."`,
    ``,
    `## Rules`,
    `- You will receive a screenshot of the current screen. Study it carefully.`,
    `- Only call ONE tool per response.`,
    `- Prefer wait(500-1500) after launching apps or before clicking.`,
    `- Use key_combo(["cmd", "space"]) to open Spotlight.`,
    `- Use open_app for known bundle IDs; fall back to Spotlight for unknown apps.`,
    `- Use click with scaled coordinates matching the screenshot dimensions.`,
    `- Call finish ONLY when the objective is fully achieved.`,
  ].join("\n");
}

// ---------------------------------------------------------------------------
// Message builder
// ---------------------------------------------------------------------------

function buildMessages(
  systemPrompt: string,
  screenshot: string,
  history: ActionEntry[]
) {
  const messages: any[] = [{ role: "system", content: systemPrompt }];

  // Replay previous tool calls so the model sees its own chain-of-thought
  for (const entry of history) {
    if (entry.role === "assistant") {
      messages.push({
        role: "assistant",
        content: `Action: ${entry.tool}(${JSON.stringify(entry.arguments)})`,
      });
    } else {
      messages.push({
        role: "user",
        content: `Result: ${entry.result ?? "completed"}`,
      });
    }
  }

  // Current screenshot
  const imageData = screenshot.startsWith("data:")
    ? screenshot
    : `data:image/jpeg;base64,${screenshot}`;

  messages.push({
    role: "user",
    content: [
      { type: "text", text: "Current screen. What is the next action?" },
      { type: "image", image: imageData },
    ],
  });

  return messages;
}

// ---------------------------------------------------------------------------
// Express app
// ---------------------------------------------------------------------------

const app = express();
app.use(cors());
app.use(express.json({ limit: "100mb" }));

app.post("/api/agent/step", async (req, res) => {
  try {
    const provider = req.headers["x-target-provider"] as
      | "ollama"
      | "anthropic"
      | "google"
      | "groq"
      | "grok"
      | undefined;
    const apiKey = req.headers["x-provider-api-key"] as string | undefined;

    const {
      modelName,
      screenshot,
      objective,
      history = [],
    } = req.body as StepRequest;

    // --- validate ---
    if (!provider || !modelName || !objective) {
      res.status(400).json({
        error:
          "Missing required fields: x-target-provider header, modelName, objective",
      });
      return;
    }
    if (!screenshot) {
      res.status(400).json({ error: "Missing screenshot" });
      return;
    }
    if (!apiKey && provider !== "ollama") {
      res.status(401).json({
        error: "Missing API key: provide x-provider-api-key header",
      });
      return;
    }

    // --- build context ---
    const system = buildSystemPrompt(objective, history);
    const messages = buildMessages(system, screenshot, history);

    // --- instantiate model (inline, key from header) ---
    let modelInstance;
    switch (provider) {
      case "ollama": {
        const baseURL =
          process.env.OLLAMA_BASE_URL || "http://localhost:11434";
        const ollama = createOllama({ baseURL });
        modelInstance = ollama.chat(modelName);
        break;
      }
      case "anthropic": {
        modelInstance = createAnthropic({ apiKey })(modelName);
        break;
      }
      case "google": {
        modelInstance = createGoogleGenerativeAI({ apiKey })(modelName);
        break;
      }
      case "groq": {
        modelInstance = createOpenAI({
          apiKey,
          baseURL: "https://api.groq.com/openai/v1",
        }).chat(modelName);
        break;
      }
      case "grok": {
        modelInstance = createOpenAI({
          apiKey,
          baseURL: "https://api.x.ai/v1",
        }).chat(modelName);
        break;
      }
      default: {
        res.status(400).json({ error: `Unsupported provider: "${provider}"` });
        return;
      }
    }

    const result = await generateText({
      model: modelInstance,
      messages,
      tools: computerTools,
      toolChoice: "required",
      maxSteps: 1,
    });

    // --- extract tool call ---
    const toolCall = result.toolCalls?.[0];

    if (!toolCall) {
      // Model returned text without a tool call (shouldn't happen with
      // toolChoice: "required", but guard anyway)
      res.json({
        tool: "finish",
        arguments: { summary: result.text || "Unable to determine next action" },
        thinking: result.text,
      } satisfies StepResponse);
      return;
    }

    res.json({
      tool: toolCall.toolName,
      arguments: toolCall.args as Record<string, unknown>,
      thinking: result.text || null,
    } satisfies StepResponse);
  } catch (error: any) {
    console.error("[/api/agent/step]", error);
    res.status(500).json({
      error: error.message ?? "Internal server error",
    });
  }
});

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------

const PORT = parseInt(process.env.PORT || "3001", 10);
app.listen(PORT, () => {
  console.log(`OpenOSUse agent server → http://localhost:${PORT}`);
  console.log(`POST /api/agent/step`);
});
