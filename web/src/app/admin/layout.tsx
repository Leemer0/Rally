import type { Metadata } from "next";
import Link from "next/link";
import { CircleHelp, ShieldCheck } from "lucide-react";
import { AdminMobileMenu, AdminSidebar } from "@/components/admin/admin-nav";
import { Badge } from "@/components/ui/badge";
import { requireFounderSession } from "@/lib/auth/founder";

export const metadata: Metadata = {
  title: "Founder admin",
  robots: { index: false, follow: false },
};
export const dynamic = "force-dynamic";

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const session = await requireFounderSession();
  const initials = session.email
    ? session.email.slice(0, 2).toUpperCase()
    : "OA";

  return (
    <div className="min-h-[100dvh] bg-[#0b0e13]">
      <a
        href="#admin-content"
        className="sr-only fixed left-4 top-4 z-50 rounded-md bg-primary px-4 py-3 text-sm font-medium text-primary-foreground focus:not-sr-only"
      >
        Skip to admin content
      </a>
      <AdminSidebar />
      <div className="lg:pl-64">
        <header className="sticky top-0 z-20 flex h-16 items-center justify-between border-b border-white/10 bg-[#0b0e13]/94 px-4 backdrop-blur-xl sm:px-6 lg:px-8">
          <div className="flex items-center gap-3">
            <AdminMobileMenu />
            <div className="flex items-center gap-2.5">
              <ShieldCheck className="hidden size-4 text-primary sm:block" />
              <div>
                <p className="text-sm font-medium">Founder admin</p>
                <p className="text-[11px] text-white/38">Outly operations</p>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2 sm:gap-3">
            <Badge
              variant="outline"
              className="rounded-sm border-primary/24 bg-primary/[0.035] text-primary"
            >
              Live data
            </Badge>
            <Link
              href="mailto:founders@getoutly.app"
              aria-label="Contact the founder team"
              className="hidden size-11 items-center justify-center rounded-md text-white/46 transition-colors hover:bg-white/5 hover:text-white sm:flex"
            >
              <CircleHelp className="size-4" />
            </Link>
            <div
              aria-label="Founder account"
              className="flex size-9 items-center justify-center rounded-full border border-white/10 bg-white/[0.055] text-xs font-medium"
            >
              {initials}
            </div>
          </div>
        </header>
        <main
          id="admin-content"
          className="mx-auto max-w-[100rem] px-4 py-6 sm:px-6 lg:px-8 lg:py-8"
        >
          {children}
        </main>
      </div>
    </div>
  );
}
