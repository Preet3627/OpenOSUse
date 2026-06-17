"use client";

import { useMemo, useState, useRef, useEffect } from "react";
import { useRouter } from "next/navigation";
import Fuse from "fuse.js";
import { Search, ArrowRight } from "lucide-react";
import { cn } from "@/lib/utils";

const PAGES = [
  { href: "/", label: "Home", section: "Landing" },
  { href: "/architecture", label: "Architecture", section: "Overview" },
  ...[
    "OpenOSUseApp", "ContentView", "PermissionManager", "ScreenCaptureEngine",
    "SystemAutomationEngine", "AgentOrchestrationLoop", "KeychainManager",
    "CoordinateAccuracyTest", "GatewayBinaryHost"
  ].map((name) => ({
    href: `/components/${name}`,
    label: `${name}.swift`,
    section: "Swift Components",
  })),
  { href: "/server/gateway", label: "Gateway Server", section: "Server" },
  { href: "/server/configuration", label: "Server Configuration", section: "Server" },
];

const fuse = new Fuse(PAGES, {
  keys: ["label", "section"],
  threshold: 0.3,
  includeScore: true,
});

export function SearchBar({ className }: { className?: string }) {
  const [query, setQuery] = useState("");
  const [isFocused, setIsFocused] = useState(false);
  const router = useRouter();
  const ref = useRef<HTMLDivElement>(null);

  const results = useMemo(
    () => (query.length > 0 ? fuse.search(query).map((r) => r.item) : []),
    [query]
  );

  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setIsFocused(false);
      }
    };
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  return (
    <div ref={ref} className={cn("relative", className)}>
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <input
          type="text"
          placeholder="Search..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => setIsFocused(true)}
          className="w-full pl-9 pr-3 py-2 text-sm bg-muted border border-border rounded-lg placeholder:text-muted-foreground text-foreground outline-none focus:ring-2 focus:ring-ring transition-shadow"
        />
      </div>

      {isFocused && query.length > 0 && results.length > 0 && (
        <div className="absolute top-full left-0 right-0 mt-1 bg-popover border border-border rounded-lg shadow-lg overflow-hidden z-20 animate-fade-in">
          {results.slice(0, 6).map((page) => (
            <button
              key={page.href}
              onClick={() => {
                setQuery("");
                setIsFocused(false);
                router.push(page.href);
              }}
              className="flex items-center justify-between w-full px-3 py-2.5 text-sm hover:bg-accent transition-colors text-left"
            >
              <div>
                <span className="text-foreground">{page.label}</span>
                <span className="ml-2 text-xs text-muted-foreground">{page.section}</span>
              </div>
              <ArrowRight className="w-3.5 h-3.5 text-muted-foreground shrink-0" />
            </button>
          ))}
        </div>
      )}

      {isFocused && query.length > 0 && results.length === 0 && (
        <div className="absolute top-full left-0 right-0 mt-1 bg-popover border border-border rounded-lg shadow-lg p-4 text-center text-sm text-muted-foreground z-20 animate-fade-in">
          No results found
        </div>
      )}
    </div>
  );
}
