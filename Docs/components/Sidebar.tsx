"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { NAV_ITEMS } from "@/lib/utils";

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-56 shrink-0 border-r border-border bg-sidebar overflow-y-auto hidden lg:block">
      <nav className="p-4 space-y-4">
        {NAV_ITEMS.map((item) => {
          const itemHref = "href" in item ? (item as { href: string }).href : undefined;
          return (
          <div key={item.label}>
            {itemHref ? (
              <Link
                href={itemHref}
                className={cn(
                  "block text-sm font-medium py-1 transition-colors",
                  pathname === itemHref
                    ? "text-foreground"
                    : "text-sidebar-muted hover:text-foreground"
                )}
              >
                {item.label}
              </Link>
            ) : (
              <div className="text-xs font-semibold uppercase tracking-wider text-sidebar-muted mb-1 px-1">
                {item.label}
              </div>
            )}
            {"items" in item && item.items && (
              <div className="ml-0 space-y-0.5">
                {item.items.map((child) => (
                  <Link
                    key={child.href}
                    href={child.href!}
                    className={cn(
                      "block text-sm py-1 px-2 rounded-md transition-colors",
                      pathname === child.href
                        ? "bg-accent text-accent-foreground font-medium"
                        : "text-sidebar-muted hover:text-sidebar-foreground hover:bg-accent/50"
                    )}
                  >
                    {child.label}
                  </Link>
                ))}
              </div>
            )}
          </div>
          );
        })}
      </nav>
    </aside>
  );
}
