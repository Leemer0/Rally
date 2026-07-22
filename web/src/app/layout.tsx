import type { Metadata, Viewport } from "next";
import { Analytics } from "@vercel/analytics/next";
import { TooltipProvider } from "@/components/ui/tooltip";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://www.getoutly.app"),
  applicationName: "Outly",
  title: {
    default: "Outly — Toronto Nightlife App",
    template: "%s | Outly",
  },
  description:
    "Outly is a free Toronto nightlife app for people tired of dating apps. See where people are going, choose a bar, and meet in real life.",
  category: "nightlife",
  creator: "Outly Labs Inc.",
  publisher: "Outly Labs Inc.",
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-image-preview": "large",
      "max-snippet": -1,
      "max-video-preview": -1,
    },
  },
  openGraph: {
    title: "Outly — Toronto Nightlife, Without the Dating App",
    description:
      "See where people are going tonight, choose a Toronto bar, and meet in real life.",
    url: "/",
    siteName: "Outly",
    locale: "en_CA",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Outly — Toronto Nightlife, Without the Dating App",
    description:
      "See where people are going tonight, choose a Toronto bar, and meet in real life.",
  },
};

export const viewport: Viewport = {
  colorScheme: "dark",
  themeColor: "#080b10",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className="h-full scroll-smooth" data-scroll-behavior="smooth">
      <body className="min-h-full bg-background font-sans text-foreground antialiased">
        <TooltipProvider>{children}</TooltipProvider>
        <Analytics />
      </body>
    </html>
  );
}
