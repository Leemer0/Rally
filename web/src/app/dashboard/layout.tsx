import type { Metadata } from "next";
import Link from "next/link";
import { CircleHelp } from "lucide-react";
import { DashboardMobileMenu, DashboardSidebar } from "@/components/dashboard/dashboard-nav";
import { Badge } from "@/components/ui/badge";
import { requireVenueSession } from "@/lib/auth/venue";

export const metadata: Metadata = {
  title: "Venue dashboard",
  robots: { index: false, follow: false },
};
export const dynamic = "force-dynamic";

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const session = await requireVenueSession();
  const navigation = {
    venueName: session.venue.name,
    registrationStatus: session.venue.registrationStatus,
  };
  const initials = session.venue.name
    .split(/\s+/)
    .slice(0, 2)
    .map((word) => word[0])
    .join("")
    .toUpperCase();

  return (
    <div className="min-h-screen bg-[#0b0e13]">
      <DashboardSidebar venue={navigation} />
      <div className="lg:pl-60">
        <header className="sticky top-0 z-20 flex h-18 items-center justify-between border-b border-white/10 bg-[#0b0e13]/92 px-4 backdrop-blur-xl sm:px-6 lg:px-8">
          <div className="flex items-center gap-3">
            <DashboardMobileMenu venue={navigation} />
            <div>
              <p className="text-sm font-medium">{session.venue.name}</p>
              <p className="text-[11px] text-white/34">{session.venue.neighbourhood ?? session.venue.city ?? "Toronto"} · Eastern Time</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <Badge variant="outline" className="hidden rounded-sm border-primary/25 text-primary capitalize sm:inline-flex">{session.venue.publicationStatus}</Badge>
            <Link href="mailto:support@getoutly.app" aria-label="Get help" className="flex size-10 items-center justify-center rounded-md text-white/42 hover:bg-white/5 hover:text-white"><CircleHelp className="size-4" /></Link>
            <div className="flex size-9 items-center justify-center rounded-full bg-white/8 text-xs font-medium">{initials || "O"}</div>
          </div>
        </header>
        <main className="mx-auto max-w-[100rem] px-4 py-7 sm:px-6 lg:px-8 lg:py-9">{children}</main>
      </div>
    </div>
  );
}
