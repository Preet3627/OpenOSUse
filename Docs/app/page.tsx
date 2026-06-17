import Link from "next/link";
import { ArrowRight, Cpu, FileCode, Server, Shield, Layers } from "lucide-react";
import { Markdown } from "@/components/Markdown";
import { readFileSync } from "fs";
import { join } from "path";

function readMD(path: string): string {
  try {
    return readFileSync(join(process.cwd(), path), "utf-8");
  } catch {
    return "";
  }
}

const componentList = [
  { name: "OpenOSUseApp", desc: "App entry point & lifecycle" },
  { name: "ContentView", desc: "Dashboard UI, controls & telemetry" },
  { name: "PermissionManager", desc: "Accessibility & Screen Recording permissions" },
  { name: "ScreenCaptureEngine", desc: "SCStream-based screen capture" },
  { name: "SystemAutomationEngine", desc: "Mouse, keyboard, app launch & coordinate scaling" },
  { name: "AgentOrchestrationLoop", desc: "5-state agent loop & server communication" },
  { name: "KeychainManager", desc: "Secure API key storage" },
  { name: "CoordinateAccuracyTest", desc: "Coordinate transform validation" },
  { name: "GatewayBinaryHost", desc: "Child process management" },
];

const features = [
  { icon: Cpu, title: "AI Vision Agent", desc: "LLM observes your screen via screenshots and controls mouse/keyboard to automate tasks" },
  { icon: Layers, title: "5-State Loop", desc: "OBSERVE → PLAN → EXECUTE → COOL DOWN → REPEAT — a robust agentic workflow" },
  { icon: Server, title: "Multi-Provider", desc: "Anthropic, Google, Groq, Grok, or Ollama — switch providers with a header" },
  { icon: Shield, title: "Keychain Security", desc: "API keys stored in macOS Keychain, injected via HTTP headers. Zero .env files" },
];

export default function Home() {
  const summary = readMD("README.md").split("## ")[1]?.split("\n").slice(1, 4).join("\n").trim() ?? "";

  return (
    <div className="space-y-16">
      {/* Hero */}
      <section className="animate-fade-in">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center">
            <span className="text-primary-foreground font-bold text-lg">O</span>
          </div>
          <div>
            <h1 className="text-3xl font-bold tracking-tight">OpenOSUse</h1>
            <p className="text-muted-foreground text-sm">AI-powered macOS computer-use agent</p>
          </div>
        </div>
        <p className="text-lg text-muted-foreground max-w-2xl leading-relaxed">
          A native macOS agent stack that lets a vision model observe your screen and
          control your mouse and keyboard to automate any desktop task.
        </p>
        <div className="flex items-center gap-3 mt-6">
          <Link
            href="/architecture"
            className="inline-flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:opacity-90 transition-opacity"
          >
            Architecture <ArrowRight className="w-4 h-4" />
          </Link>
          <Link
            href="/server/gateway"
            className="inline-flex items-center gap-2 px-4 py-2 bg-secondary text-secondary-foreground rounded-lg text-sm font-medium hover:bg-accent transition-colors"
          >
            Gateway Server <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      </section>

      {/* Features */}
      <section className="animate-fade-in">
        <h2 className="text-xl font-semibold mb-4">Key Features</h2>
        <div className="grid sm:grid-cols-2 gap-3">
          {features.map((f) => (
            <div
              key={f.title}
              className="p-4 rounded-xl border border-border bg-card hover:bg-accent/50 transition-colors"
            >
              <div className="flex items-center gap-3 mb-2">
                <f.icon className="w-5 h-5 text-primary" />
                <h3 className="font-medium text-sm">{f.title}</h3>
              </div>
              <p className="text-sm text-muted-foreground leading-relaxed">{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Architecture diagram */}
      <section className="animate-fade-in">
        <h2 className="text-xl font-semibold mb-4">Architecture</h2>
        <div className="p-6 rounded-xl border border-border bg-card">
          <pre className="text-xs leading-relaxed text-muted-foreground !bg-transparent !border-none !p-0 overflow-x-auto">
{`┌─────────────────────────────────────────────────────┐
│              OpenOSUse.app (Swift)                   │
│  ┌──────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │Permission│  │ ScreenCapture  │  │SystemAuto-   │  │
│  │ Manager  │  │ Engine         │  │mationEngine  │  │
│  └──────────┘  └───────┬────────┘  └──────┬───────┘  │
│                         │                  │          │
│  ┌──────────────────────▼──────────────────▼───────┐  │
│  │            AgentOrchestrationLoop               │  │
│  │   OBSERVE → PLAN → EXECUTE → COOL DOWN → REPEAT │  │
│  └───────────────────────┬─────────────────────────┘  │
│                          │ POST + API Key header       │
│                          ▼                            │
│                 ┌──────────────────┐                   │
│                 │ GatewayBinaryHost│ ← child Process   │
│                 └──────────────────┘                   │
└──────────────────────┬───────────────────────────────┘
                       │ localhost:3001
                       ▼
┌─────────────────────────────────────────────────────┐
│          OpenOSUseGateway (TypeScript)               │
│  POST /api/agent/step → route to AI provider         │
│  Anthropic / Google / Groq / Grok / Ollama           │
│  generateText({ toolChoice: "required" })            │
└─────────────────────────────────────────────────────┘`}
          </pre>
        </div>
      </section>

      {/* Components grid */}
      <section className="animate-fade-in">
        <h2 className="text-xl font-semibold mb-4">Swift Components</h2>
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-2">
          {componentList.map((c) => (
            <Link
              key={c.name}
              href={`/components/${c.name}`}
              className="flex items-center justify-between p-3 rounded-lg border border-border hover:bg-accent hover:border-primary/30 transition-all group"
            >
              <div>
                <div className="text-sm font-medium group-hover:text-primary transition-colors">
                  {c.name}
                </div>
                <div className="text-xs text-muted-foreground">{c.desc}</div>
              </div>
              <ArrowRight className="w-4 h-4 text-muted-foreground group-hover:text-primary shrink-0 transition-colors" />
            </Link>
          ))}
        </div>
      </section>

      {/* Server */}
      <section className="animate-fade-in">
        <h2 className="text-xl font-semibold mb-4">Server</h2>
        <div className="grid sm:grid-cols-2 gap-2">
          <Link
            href="/server/gateway"
            className="flex items-center justify-between p-3 rounded-lg border border-border hover:bg-accent hover:border-primary/30 transition-all group"
          >
            <div>
              <div className="text-sm font-medium group-hover:text-primary transition-colors">
                <FileCode className="w-4 h-4 inline mr-2" />
                Gateway Server
              </div>
              <div className="text-xs text-muted-foreground">Express + Vercel AI SDK</div>
            </div>
            <ArrowRight className="w-4 h-4 text-muted-foreground group-hover:text-primary shrink-0" />
          </Link>
          <Link
            href="/server/configuration"
            className="flex items-center justify-between p-3 rounded-lg border border-border hover:bg-accent hover:border-primary/30 transition-all group"
          >
            <div>
              <div className="text-sm font-medium group-hover:text-primary transition-colors">
                Configuration
              </div>
              <div className="text-xs text-muted-foreground">package.json, tsconfig, scripts</div>
            </div>
            <ArrowRight className="w-4 h-4 text-muted-foreground group-hover:text-primary shrink-0" />
          </Link>
        </div>
      </section>

      {/* Data Flow */}
      <section className="animate-fade-in">
        <h2 className="text-xl font-semibold mb-4">Data Flow</h2>
        <div className="space-y-0">
          {[
            { step: "1 OBSERVE", desc: "ScreenCaptureEngine captures a screenshot (1280px, JPEG)" },
            { step: "2 PLAN", desc: "Base64 screenshot POSTed to gateway with X-Provider-API-Key header" },
            { step: "3 ROUTE", desc: "Gateway instantiates the correct AI provider with the header-derived key" },
            { step: "4 GENERATE", desc: "generateText({ toolChoice: \"required\" }) returns a tool call" },
            { step: "5 EXECUTE", desc: "SystemAutomationEngine performs the action (click, type, app launch, etc.)" },
            { step: "6 COOL DOWN", desc: "500ms pause for UI to settle, then repeat from step 1" },
          ].map(({ step, desc }) => (
            <div key={step} className="flex items-start gap-3 py-2 border-b border-border last:border-0">
              <span className="text-xs font-semibold text-primary bg-primary/10 px-2 py-0.5 rounded shrink-0 mt-0.5">
                {step}
              </span>
              <span className="text-sm text-muted-foreground">{desc}</span>
            </div>
          ))}
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-border pt-6 text-center text-xs text-muted-foreground">
        <p>OpenOSUse &copy; {new Date().getFullYear()} &mdash; MIT License</p>
        <p className="mt-1">
          Built with Next.js, Tailwind CSS, Radix UI, cmdk, Framer Motion &middot;{" "}
          <a href="https://github.com/Preet3627/OpenOSUse" className="underline hover:text-foreground transition-colors" target="_blank" rel="noopener noreferrer">
            GitHub
          </a>
        </p>
      </footer>
    </div>
  );
}
