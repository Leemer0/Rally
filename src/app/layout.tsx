import type { Metadata, Viewport } from "next";
import "@fontsource-variable/instrument-sans";

import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "Outly",
    template: "%s · Outly",
  },
  description: "See where Toronto is going tonight.",
  applicationName: "Outly",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "Outly",
  },
  formatDetection: {
    telephone: false,
  },
  icons: {
    icon: "/brand/outly-mark.svg",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  viewportFit: "cover",
  themeColor: "#080B10",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
