import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export const NAV_ITEMS = [
  { href: "/", label: "Home" },
  {
    label: "Swift App",
    items: [
      { href: "/components/OpenOSUseApp", label: "OpenOSUseApp" },
      { href: "/components/ContentView", label: "ContentView" },
      { href: "/components/PermissionManager", label: "PermissionManager" },
      { href: "/components/ScreenCaptureEngine", label: "ScreenCaptureEngine" },
      { href: "/components/AXElementReader", label: "AXElementReader" },
      { href: "/components/SystemAutomationEngine", label: "SystemAutomationEngine" },
      { href: "/components/AgentOrchestrationLoop", label: "AgentOrchestrationLoop" },
      { href: "/components/MCPServer", label: "MCPServer" },
      { href: "/components/KeychainManager", label: "KeychainManager" },
      { href: "/components/CoordinateAccuracyTest", label: "CoordinateAccuracyTest" },
      { href: "/components/GatewayBinaryHost", label: "GatewayBinaryHost" },
    ],
  },
  {
    label: "Server",
    items: [
      { href: "/server/gateway", label: "Gateway Server" },
      { href: "/server/configuration", label: "Configuration" },
    ],
  },
  { href: "/architecture", label: "Architecture" },
] as const;

export interface NavItem {
  href?: string;
  label: string;
  items?: readonly NavItem[];
}

export const TITLE = "OpenOSUse";
export const DESCRIPTION = "AI-powered macOS computer-use agent — documentation & reference";
