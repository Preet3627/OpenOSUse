"use client";

import { useEffect, useState } from "react";
import { Download, Github, ExternalLink, Tag, Calendar } from "lucide-react";

interface Release {
  tag_name: string;
  name: string;
  body: string;
  published_at: string;
  html_url: string;
  assets: { name: string; download_count: number; browser_download_url: string }[];
}

export function DownloadSection() {
  const [releases, setReleases] = useState<Release[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("https://api.github.com/repos/Preet3627/OpenOSUse/releases")
      .then((r) => r.json())
      .then((data) => {
        if (Array.isArray(data)) setReleases(data.slice(0, 3));
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <section className="animate-fade-in">
        <h2 className="text-xl font-semibold mb-4">Downloads</h2>
        <div className="p-8 rounded-xl border border-border bg-card text-center text-muted-foreground text-sm">
          Loading releases...
        </div>
      </section>
    );
  }

  if (releases.length === 0) {
    return (
      <section className="animate-fade-in">
        <h2 className="text-xl font-semibold mb-4">Downloads</h2>
        <div className="p-8 rounded-xl border border-border bg-card text-center text-muted-foreground text-sm">
          <Github className="w-8 h-8 mx-auto mb-2 opacity-40" />
          No releases found. Check{" "}
          <a href="https://github.com/Preet3627/OpenOSUse/releases" target="_blank" rel="noopener noreferrer" className="text-primary underline">
            GitHub Releases
          </a>
        </div>
      </section>
    );
  }

  return (
    <section className="animate-fade-in">
      <h2 className="text-xl font-semibold mb-4 flex items-center gap-2">
        <Download className="w-5 h-5 text-primary" />
        Downloads
      </h2>
      <div className="space-y-3">
        {releases.map((release) => (
          <div
            key={release.tag_name}
            className="p-4 rounded-xl border border-border bg-card hover:border-primary/30 transition-all group"
          >
            <div className="flex items-start justify-between gap-4">
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <Tag className="w-4 h-4 text-primary shrink-0" />
                  <a
                    href={release.html_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="font-semibold text-sm hover:text-primary transition-colors"
                  >
                    {release.name || release.tag_name}
                  </a>
                </div>
                <div className="flex items-center gap-3 text-xs text-muted-foreground">
                  <span className="flex items-center gap-1">
                    <Calendar className="w-3 h-3" />
                    {new Date(release.published_at).toLocaleDateString("en-US", {
                      year: "numeric", month: "short", day: "numeric",
                    })}
                  </span>
                  {release.assets.length > 0 && (
                    <span>{release.assets[0].download_count.toLocaleString()} downloads</span>
                  )}
                </div>
                {release.body && (
                  <p className="text-xs text-muted-foreground mt-2 line-clamp-2">
                    {release.body.replace(/^##\s*.+/m, "").trim().slice(0, 200)}
                  </p>
                )}
              </div>
              <div className="flex items-center gap-2 shrink-0">
                {release.assets.length > 0 && (
                  <a
                    href={release.assets[0].browser_download_url}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg btn-gradient"
                  >
                    <Download className="w-3.5 h-3.5" />
                    Download
                  </a>
                )}
                <a
                  href={release.html_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg border border-border hover:bg-accent transition-colors text-muted-foreground hover:text-foreground"
                >
                  <ExternalLink className="w-3.5 h-3.5" />
                  Release
                </a>
              </div>
            </div>
          </div>
        ))}
      </div>
      <div className="mt-3 text-center">
        <a
          href="https://github.com/Preet3627/OpenOSUse/releases"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1.5 text-xs text-muted-foreground hover:text-foreground transition-colors"
        >
          View all releases on GitHub <ExternalLink className="w-3 h-3" />
        </a>
      </div>
    </section>
  );
}
