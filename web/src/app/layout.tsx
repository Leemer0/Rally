import type { Metadata, Viewport } from "next";
import { TooltipProvider } from "@/components/ui/tooltip";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://getoutly.app"),
  applicationName: "Outly",
  title: {
    default: "Outly",
    template: "%s | Outly",
  },
  description:
    "See where Toronto is going tonight. Pick a bar. Meet in real life.",
  alternates: {
    canonical: "/",
  },
  openGraph: {
    title: "Outly — Meet in real life.",
    description: "See where Toronto is going tonight. Pick a bar. Meet in real life.",
    url: "/",
    siteName: "Outly",
    locale: "en_CA",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Outly — Meet in real life.",
    description: "See where Toronto is going tonight. Pick a bar. Meet in real life.",
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
      </body>
    </html>
  );
}
