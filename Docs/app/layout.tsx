import type { Metadata } from "next";
import { ThemeProvider } from "@/components/ThemeProvider";
import { Header } from "@/components/Header";
import { Sidebar } from "@/components/Sidebar";
import { DESCRIPTION, TITLE } from "@/lib/utils";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: TITLE, template: `%s — ${TITLE}` },
  description: DESCRIPTION,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ThemeProvider>
          <div className="min-h-screen flex flex-col">
            <Header />
            <div className="flex flex-1 max-w-[1440px] mx-auto w-full">
              <Sidebar />
              <main className="flex-1 min-w-0 px-4 sm:px-6 lg:px-8 py-8">
                {children}
              </main>
            </div>
          </div>
        </ThemeProvider>
      </body>
    </html>
  );
}
