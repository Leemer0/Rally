import type { Metadata } from "next";
import Link from "next/link";
import { CircleHelp } from "lucide-react";
import { DashboardMobileMenu, DashboardSidebar } from "@/components/dashboard/dashboard-nav";
import { Badge } from "@/components/ui/badge";

export const metadata: Metadata = { title: "Venue dashboard" };

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-[#0b0e13]">
      <DashboardSidebar />
      <div className="lg:pl-60">
        <header className="sticky top-0 z-20 flex h-18 items-center justify-between border-b border-white/10 bg-[#0b0e13]/92 px-4 backdrop-blur-xl sm:px-6 lg:px-8">
          <div className="flex items-center gap-3">
            <DashboardMobileMenu />
            <div>
              <p className="text-sm font-medium">Demo Venue</p>
              <p className="text-[11px] text-white/34">Toronto · Eastern Time</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <Badge variant="outline" className="hidden rounded-sm border-primary/25 text-primary sm:inline-flex">Demo data</Badge>
            <Link href="mailto:support@getoutly.app" aria-label="Get help" className="flex size-10 items-center justify-center rounded-md text-white/42 hover:bg-white/5 hover:text-white"><CircleHelp className="size-4" /></Link>
            <div className="flex size-9 items-center justify-center rounded-full bg-white/8 text-xs font-medium">DV</div>
          </div>
        </header>
        <main className="mx-auto max-w-[100rem] px-4 py-7 sm:px-6 lg:px-8 lg:py-9">{children}</main>
      </div>
    </div>
  );
}
