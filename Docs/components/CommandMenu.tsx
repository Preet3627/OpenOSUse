"use client";

import { useEffect, useCallback, useState, useRef } from "react";
import { useRouter } from "next/navigation";
import { Command } from "cmdk";
import { Search, FileText, Server, Cpu, BookOpen } from "lucide-react";
import { cn } from "@/lib/utils";

const COMPONENT_NAMES = [
  "OpenOSUseApp", "ContentView", "PermissionManager", "ScreenCaptureEngine",
  "SystemAutomationEngine", "AgentOrchestrationLoop", "KeychainManager",
  "CoordinateAccuracyTest", "GatewayBinaryHost",
] as const;

const PAGES = [
  { href: "/", label: "Home — Landing", icon: BookOpen },
  { href: "/architecture", label: "Architecture Overview", icon: Cpu },
  ...COMPONENT_NAMES.map((name) => ({
    href: `/components/${name}`,
    label: `${name}.swift`,
    icon: FileText,
  })),
  { href: "/server/gateway", label: "Gateway Server (server.ts)", icon: Server },
  { href: "/server/configuration", label: "Server Configuration", icon: Server },
];

export function CommandMenu() {
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState("");
  const router = useRouter();
  const inputRef = useRef<HTMLInputElement>(null);

  const toggle = useCallback(() => setOpen((o) => !o), []);

  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        toggle();
      }
      if (e.key === "Escape" && open) {
        setOpen(false);
      }
    };
    document.addEventListener("keydown", down);
    return () => document.removeEventListener("keydown", down);
  }, [toggle, open]);

  useEffect(() => {
    if (open) {
      setSearch("");
      setTimeout(() => inputRef.current?.focus(), 50);
    }
  }, [open]);

  const runCommand = (href: string) => {
    setOpen(false);
    router.push(href);
  };

  return (
    <>
      <button
        onClick={toggle}
        className="flex items-center gap-2 px-3 py-1.5 text-sm text-muted-foreground bg-muted rounded-lg border border-border hover:text-foreground transition-colors w-full max-w-[240px]"
      >
        <Search className="w-4 h-4 shrink-0" />
        <span className="flex-1 text-left">Search docs...</span>
        <kbd className="hidden md:inline-flex items-center gap-0.5 px-1.5 py-0.5 text-[10px] font-medium bg-background border border-border rounded">
          <span>⌘</span>K
        </kbd>
      </button>

      {open && (
        <div
          className="fixed inset-0 z-50"
          onClick={() => setOpen(false)}
        >
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm" />
          <div
            className="fixed top-[15%] left-1/2 -translate-x-1/2 w-full max-w-[560px] bg-popover border border-border rounded-xl shadow-2xl overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <Command className="[&_[cmdk-input]]:border-none" label="Search">
              <div className="flex items-center border-b border-border px-3">
                <Search className="w-4 h-4 text-muted-foreground shrink-0" />
                <Command.Input
                  ref={inputRef}
                  value={search}
                  onValueChange={setSearch}
                  placeholder="Search documentation..."
                  className="w-full bg-transparent px-3 py-3 text-sm outline-none placeholder:text-muted-foreground"
                />
                <kbd className="text-[10px] text-muted-foreground font-medium px-1.5 py-0.5 border border-border rounded">
                  ESC
                </kbd>
              </div>
              <Command.List className="max-h-[320px] overflow-y-auto p-2">
                <Command.Empty className="py-8 text-center text-sm text-muted-foreground">
                  No results found.
                </Command.Empty>
                <Command.Group heading="Pages">
                  {PAGES.filter((p) =>
                    p.label.toLowerCase().includes(search.toLowerCase())
                  ).map(({ href, label, icon: Icon }) => (
                    <Command.Item
                      key={href}
                      value={label}
                      onSelect={() => runCommand(href)}
                      className="flex items-center gap-3 px-3 py-2.5 text-sm rounded-lg cursor-pointer aria-selected:bg-accent"
                    >
                      <Icon className="w-4 h-4 text-muted-foreground shrink-0" />
                      <span>{label}</span>
                    </Command.Item>
                  ))}
                </Command.Group>
              </Command.List>
            </Command>
          </div>
        </div>
      )}
    </>
  );
}
