"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Building2,
  Handshake,
  LayoutDashboard,
  LogOut,
  Menu,
  Send,
  ShieldCheck,
  Users,
} from "lucide-react";
import { BrandMark } from "@/components/brand/mark";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { cn } from "@/lib/utils";
import { signOutVenue } from "@/app/venue/actions";

const navItems = [
  { href: "/admin", label: "Overview", icon: LayoutDashboard },
  { href: "/admin/venues", label: "Venues", icon: Building2 },
  { href: "/admin/users", label: "Users", icon: Users },
  { href: "/admin/partners", label: "Partners", icon: Handshake },
  { href: "/admin/assignments", label: "Offer approvals", icon: Send },
];

function NavContent() {
  const pathname = usePathname();

  return (
    <>
      <div className="flex h-16 items-center border-b border-sidebar-border px-5">
        <BrandMark className="h-7 w-14" />
        <span className="ml-3 border-l border-white/14 pl-3 text-xs font-medium text-white/58">
          Founder admin
        </span>
      </div>

      <nav className="flex-1 p-3" aria-label="Founder admin">
        <p className="px-3 pb-2 pt-3 font-mono text-[9px] uppercase tracking-[0.16em] text-white/34">
          Operations
        </p>
        <div className="space-y-1">
          {navItems.map((item) => {
            const active =
              item.href === "/admin"
                ? pathname === item.href
                : pathname.startsWith(item.href);
            const Icon = item.icon;

            return (
              <Link
                key={item.href}
                href={item.href}
                aria-current={active ? "page" : undefined}
                className={cn(
                  "flex min-h-11 items-center gap-3 rounded-md px-3 text-sm text-white/58 transition-colors hover:bg-white/[0.05] hover:text-white",
                  active && "bg-white/[0.075] font-medium text-white",
                )}
              >
                <Icon
                  className={cn(
                    "size-4",
                    active ? "text-primary" : "text-white/38",
                  )}
                  strokeWidth={1.8}
                />
                {item.label}
              </Link>
            );
          })}
        </div>
      </nav>

      <div className="border-t border-sidebar-border p-3">
        <form action={signOutVenue}>
          <button
            type="submit"
            className="flex min-h-11 w-full items-center gap-3 rounded-md px-3 text-sm text-white/50 transition-colors hover:bg-white/[0.05] hover:text-white"
          >
            <LogOut className="size-4 text-white/36" strokeWidth={1.8} />
            Sign out
          </button>
        </form>
      </div>

      <div className="border-t border-sidebar-border px-5 py-4">
        <div className="flex items-center gap-2 text-xs font-medium text-white/68">
          <ShieldCheck className="size-4 text-primary" strokeWidth={1.8} />
          Founder access
        </div>
        <p className="mt-1.5 text-[11px] leading-4 text-white/34">
          Access is verified against the founder allowlist.
        </p>
      </div>
    </>
  );
}

export function AdminSidebar() {
  return (
    <aside className="fixed inset-y-0 left-0 z-30 hidden w-64 flex-col border-r border-sidebar-border bg-sidebar lg:flex">
      <NavContent />
    </aside>
  );
}

export function AdminMobileMenu() {
  return (
    <Sheet>
      <SheetTrigger
        render={
          <Button
            variant="outline"
            size="icon-lg"
            className="size-11 border-white/12 bg-transparent lg:hidden"
            aria-label="Open founder admin menu"
          />
        }
      >
        <Menu className="size-5" />
      </SheetTrigger>
      <SheetContent
        side="left"
        className="w-[18rem] border-white/10 bg-sidebar p-0"
        showCloseButton={false}
      >
        <SheetHeader className="sr-only">
          <SheetTitle>Founder admin navigation</SheetTitle>
          <SheetDescription>Choose an admin page</SheetDescription>
        </SheetHeader>
        <NavContent />
      </SheetContent>
    </Sheet>
  );
}
