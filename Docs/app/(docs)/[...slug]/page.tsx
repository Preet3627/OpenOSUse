import { Metadata } from "next";
import { notFound } from "next/navigation";
import { readFileSync } from "fs";
import { join } from "path";
import { Markdown } from "@/components/Markdown";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";

const CONTENT_MAP: Record<string, { path: string; title: string }> = {
  "components/OpenOSUseApp": {
    path: "content/components/OpenOSUseApp.md",
    title: "OpenOSUseApp.swift",
  },
  "components/ContentView": {
    path: "content/components/ContentView.md",
    title: "ContentView.swift",
  },
  "components/PermissionManager": {
    path: "content/components/PermissionManager.md",
    title: "PermissionManager.swift",
  },
  "components/ScreenCaptureEngine": {
    path: "content/components/ScreenCaptureEngine.md",
    title: "ScreenCaptureEngine.swift",
  },
  "components/SystemAutomationEngine": {
    path: "content/components/SystemAutomationEngine.md",
    title: "SystemAutomationEngine.swift",
  },
  "components/AgentOrchestrationLoop": {
    path: "content/components/AgentOrchestrationLoop.md",
    title: "AgentOrchestrationLoop.swift",
  },
  "components/KeychainManager": {
    path: "content/components/KeychainManager.md",
    title: "KeychainManager.swift",
  },
  "components/CoordinateAccuracyTest": {
    path: "content/components/CoordinateAccuracyTest.md",
    title: "CoordinateAccuracyTest.swift",
  },
  "components/GatewayBinaryHost": {
    path: "content/components/GatewayBinaryHost.md",
    title: "GatewayBinaryHost.swift",
  },
  "server/gateway": {
    path: "content/server/gateway.md",
    title: "Gateway Server",
  },
  "server/configuration": {
    path: "content/server/configuration.md",
    title: "Server Configuration",
  },
  architecture: {
    path: "content/ARCHITECTURE.md",
    title: "Architecture",
  },
};

export function generateStaticParams() {
  return Object.keys(CONTENT_MAP).map((slug) => ({
    slug: slug.split("/"),
  }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string[] }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const key = slug.join("/");
  const entry = CONTENT_MAP[key];
  if (!entry) return { title: "Not Found" };
  return { title: entry.title };
}

export default async function DocPage({
  params,
}: {
  params: Promise<{ slug: string[] }>;
}) {
  const { slug } = await params;
  const key = slug.join("/");
  const entry = CONTENT_MAP[key];

  if (!entry) notFound();

  let content: string;
  try {
    content = readFileSync(join(process.cwd(), entry.path), "utf-8");
  } catch {
    content = "Content not found.";
  }

  // Strip the first heading title since we show it in the page heading
  const body = content.replace(/^# .+\n/, "").trim();

  return (
    <div className="animate-fade-in">
      <Link
        href="/"
        className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground mb-4 transition-colors"
      >
        <ArrowLeft className="w-3 h-3" />
        Back to Home
      </Link>
      <h1 className="text-2xl font-bold tracking-tight mb-6">{entry.title}</h1>
      <Markdown content={body} />
    </div>
  );
}
