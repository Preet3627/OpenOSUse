import Link from "next/link";
import { ArrowRight, Cpu, FileCode, Server, Shield, Layers, Download, Github, Star, GitFork, Terminal } from "lucide-react";
import { DownloadSection } from "@/components/DownloadSection";

const componentList = [
  { name: "OpenOSUseApp", desc: "App entry point & lifecycle" },
  { name: "ContentView", desc: "Dashboard UI, controls & telemetry" },
  { name: "PermissionManager", desc: "Accessibility & Screen Recording permissions" },
  { name: "ScreenCaptureEngine", desc: "SCStream-based screen capture" },
  { name: "AXElementReader", desc: "Accessibility Tree snapshot" },
  { name: "SystemAutomationEngine", desc: "Mouse, keyboard, app launch" },
  { name: "AgentOrchestrationLoop", desc: "5-state agent loop & AX support" },
  { name: "MCPServer", desc: "MCP protocol server" },
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

function Badge({ href, src, alt }: { href: string; src: string; alt: string }) {
  return (
    <a href={href} target="_blank" rel="noopener noreferrer" className="inline-block">
      <img src={src} alt={alt} className="h-6" />
    </a>
  );
}

export default function Home() {
  return (
    <div className="space-y-16">
      {/* Hero */}
      <section className="relative overflow-hidden rounded-2xl p-8 gradient-hero border border-border">
        <div className="relative z-10">
          <div className="flex items-center gap-3 mb-4">
            <img src="/logo.png" alt="OpenOSUse" className="w-10 h-10 rounded-xl" />
            <div>
              <h1 className="text-3xl font-bold tracking-tight">OpenOSUse</h1>
              <p className="text-muted-foreground text-sm">AI-powered macOS computer-use agent</p>
            </div>
          </div>

          <p className="text-lg text-muted-foreground max-w-2xl leading-relaxed">
            A native macOS agent stack that lets a vision model observe your screen and
            control your mouse and keyboard to automate any desktop task.
            <span className="text-primary font-medium"> Open source. Permission-gated. Multi-provider.</span>
          </p>

          {/* Repo Status */}
          <div className="flex flex-wrap items-center gap-3 mt-5">
            <Badge href="https://github.com/Preet3627/OpenOSUse" src="https://img.shields.io/github/stars/Preet3627/OpenOSUse?style=for-the-badge&logo=github&color=cyan" alt="Stars" />
            <Badge href="https://github.com/Preet3627/OpenOSUse/forks" src="https://img.shields.io/github/forks/Preet3627/OpenOSUse?style=for-the-badge&logo=github&color=blue" alt="Forks" />
            <Badge href="https://github.com/Preet3627/OpenOSUse/releases" src="https://img.shields.io/github/v/release/Preet3627/OpenOSUse?style=for-the-badge&logo=github&color=brightgreen" alt="Version" />
            <Badge href="https://github.com/Preet3627/OpenOSUse/issues" src="https://img.shields.io/github/issues/Preet3627/OpenOSUse?style=for-the-badge&logo=github&color=orange" alt="Issues" />
            <Badge href="https://github.com/Preet3627/OpenOSUse/blob/main/LICENSE" src="https://img.shields.io/badge/License-Apache_2.0-cyan?style=for-the-badge" alt="License" />
            <Badge href="https://github.com/Preet3627/OpenOSUse/actions" src="https://img.shields.io/github/actions/workflow/status/Preet3627/OpenOSUse/release.yml?style=for-the-badge&logo=github&color=brightgreen" alt="Build" />
          </div>

          <div className="flex items-center gap-3 mt-6">
            <Link
              href="/architecture"
              className="btn-gradient inline-flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-semibold"
            >
              Architecture <ArrowRight className="w-4 h-4" />
            </Link>
            <Link
              href="/server/gateway"
              className="btn-vibrant inline-flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-medium border border-border bg-card hover:bg-accent transition-colors"
            >
              <Terminal className="w-4 h-4" />
              Gateway Server
            </Link>
            <a
              href="https://github.com/Preet3627/OpenOSUse"
              target="_blank"
              rel="noopener noreferrer"
              className="btn-vibrant inline-flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-medium border border-border bg-card hover:bg-accent transition-colors"
            >
              <Github className="w-4 h-4" />
              GitHub
            </a>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="animate-fade-in">
        <h2 className="text-xl font-semibold mb-4">Key Features</h2>
        <div className="grid sm:grid-cols-2 gap-3">
          {features.map((f, i) => (
            <div
              key={f.title}
              className={`p-4 rounded-xl border border-border bg-card hover:bg-accent/50 transition-all group ${
                i === 0 ? "gradient-card-1" : i === 1 ? "gradient-card-2" : i === 2 ? "gradient-card-3" : "gradient-card-4"
              }`}
            >
              <div className="flex items-center gap-3 mb-2">
                <div className="p-1.5 rounded-lg bg-primary/10">
                  <f.icon className="w-5 h-5 text-primary" />
                </div>
                <h3 className="font-medium text-sm">{f.title}</h3>
              </div>
              <p className="text-sm text-muted-foreground leading-relaxed">{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Architecture diagram */}
      <section className="animate-fade-in">
        <h2 className="text-xl font-semibold mb-4 flex items-center gap-2">
          <Layers className="w-5 h-5 text-primary" />
          Architecture
        </h2>
        <div className="p-6 rounded-xl border border-border bg-card gradient-card-1">
          <pre className="text-xs leading-relaxed text-muted-foreground !bg-transparent !border-none !p-0 overflow-x-auto">
{`┌─────────────────────────────────────────────────────┐
│              OpenOSUse.app (Swift)                   │
│  ┌──────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │Permission│  │ ScreenCapture  │  │AXElement-   │  │
│  │ Manager  │  │ Engine         │  │Reader       │  │
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
│                 ┌──────────────────┐                   │
│                 │ MCPServer (TCP)  │ ← MCP clients     │
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

      {/* Download Section */}
      <DownloadSection />

      {/* Data Flow */}
      <section className="animate-fade-in">
        <h2 className="text-xl font-semibold mb-4">Data Flow</h2>
        <div className="space-y-0">
          {[
            { step: "1 OBSERVE", desc: "ScreenCaptureEngine captures a screenshot (1280px, JPEG). Optional AX Tree readout." },
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
        <p>OpenOSUse &copy; {new Date().getFullYear()} &mdash; Apache 2.0 License</p>
        <p className="mt-1">
          Built with SwiftUI, Next.js, Tailwind CSS, Radix UI &middot;{" "}
          <a href="https://github.com/Preet3627/OpenOSUse" className="underline hover:text-foreground transition-colors" target="_blank" rel="noopener noreferrer">
            GitHub
          </a>
          {" "}&middot;{" "}
          <a href="https://github.com/Preet3627/OpenOSUse/releases" className="underline hover:text-foreground transition-colors" target="_blank" rel="noopener noreferrer">
            Releases
          </a>
        </p>
      </footer>
    </div>
  );
}
