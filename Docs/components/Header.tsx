"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Menu, Github } from "lucide-react";
import { useState } from "react";
import { cn } from "@/lib/utils";
import { ThemeToggle } from "./ThemeToggle";
import { CommandMenu } from "./CommandMenu";
import { NAV_ITEMS } from "@/lib/utils";

export function Header() {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <>
      <header className="sticky top-0 z-40 w-full border-b border-border bg-background/80 backdrop-blur-md">
        <div className="flex items-center justify-between h-14 px-4 max-w-[1440px] mx-auto">
          {/* Left */}
          <div className="flex items-center gap-4">
            <button
              onClick={() => setMobileOpen(!mobileOpen)}
              className="lg:hidden p-1.5 -ml-1.5 text-muted-foreground hover:text-foreground"
            >
              <Menu className="w-5 h-5" />
            </button>
            <Link href="/" className="flex items-center gap-2">
              <img
                src="/logo.png"
                alt="OpenOSUse"
                className="w-7 h-7 rounded-lg"
              />
              <span className="font-semibold text-sm hidden sm:block">OpenOSUse</span>
            </Link>
          </div>

          {/* Center */}
          <div className="hidden md:flex items-center gap-1">
            {NAV_ITEMS.filter((item): item is typeof item & { href: string } => "href" in item).map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "px-3 py-1.5 text-sm rounded-md transition-colors",
                  pathname === item.href
                    ? "text-foreground font-medium"
                    : "text-muted-foreground hover:text-foreground"
                )}
              >
                {item.label}
              </Link>
            ))}
          </div>

          {/* Right */}
          <div className="flex items-center gap-2">
            <CommandMenu />
            <ThemeToggle className="hidden sm:flex" />
            <a
              href="https://github.com/Preet3627/OpenOSUse"
              target="_blank"
              rel="noopener noreferrer"
              className="p-1.5 text-muted-foreground hover:text-foreground transition-colors"
            >
              <Github className="w-4 h-4" />
            </a>
          </div>
        </div>
      </header>

      {/* Mobile nav */}
      {mobileOpen && (
        <div className="lg:hidden fixed inset-0 z-30" onClick={() => setMobileOpen(false)}>
          <div className="fixed inset-0 bg-black/30" />
          <nav className="fixed top-14 left-0 bottom-0 w-64 bg-sidebar border-r border-border p-4 overflow-y-auto animate-fade-in">
            <div className="space-y-4">
              {NAV_ITEMS.map((item) => {
                const itemHref = "href" in item ? (item as { href: string }).href : undefined;
                return (
                <div key={item.label}>
                  {itemHref ? (
                    <Link
                      href={itemHref!}
                      onClick={() => setMobileOpen(false)}
                      className="block text-sm font-medium py-1 text-sidebar-foreground"
                    >
                      {item.label}
                    </Link>
                  ) : (
                    <div className="text-xs font-semibold uppercase tracking-wider text-sidebar-muted mb-1 px-1">
                      {item.label}
                    </div>
                  )}
                  {"items" in item && item.items?.map((child) => (
                    <Link
                      key={child.href}
                      href={child.href!}
                      onClick={() => setMobileOpen(false)}
                      className={cn(
                        "block text-sm py-1 px-2 rounded-md transition-colors",
                        pathname === child.href
                          ? "bg-accent text-accent-foreground font-medium"
                          : "text-sidebar-muted hover:text-sidebar-foreground"
                      )}
                    >
                      {child.label}
                    </Link>
                  ))}
                </div>
                );
              })}
            </div>
          </nav>
        </div>
      )}
    </>
  );
}
