"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { BarChart3, Building2, CreditCard, Gift, LayoutDashboard, LogOut, Menu, Settings } from "lucide-react";
import { BrandMark } from "@/components/brand/mark";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet";
import { cn } from "@/lib/utils";

const navItems = [
  { href: "/dashboard", label: "Overview", icon: LayoutDashboard },
  { href: "/dashboard/analytics", label: "Analytics", icon: BarChart3 },
  { href: "/dashboard/offers", label: "Offers", icon: Gift },
  { href: "/dashboard/venue", label: "Venue profile", icon: Building2 },
  { href: "/dashboard/billing", label: "Plan & billing", icon: CreditCard },
];

function NavContent() {
  const pathname = usePathname();
  return (
    <>
      <div className="flex h-18 items-center border-b border-sidebar-border px-5">
        <BrandMark className="h-8 w-16" />
        <span className="ml-3 border-l border-white/14 pl-3 text-xs text-white/42">Venue</span>
      </div>
      <nav className="flex-1 space-y-1 p-3" aria-label="Dashboard">
        <p className="px-3 pb-2 pt-3 font-mono text-[9px] uppercase tracking-[0.17em] text-white/28">Workspace</p>
        {navItems.map((item) => {
          const active = item.href === "/dashboard" ? pathname === item.href : pathname.startsWith(item.href);
          const Icon = item.icon;
          return (
            <Link key={item.href} href={item.href} className={cn("flex min-h-10 items-center gap-3 rounded-md px-3 text-sm text-white/52 transition-colors hover:bg-white/[0.045] hover:text-white", active && "bg-white/[0.065] text-white")}>
              <Icon className={cn("size-4", active ? "text-primary" : "text-white/34")} />
              {item.label}
            </Link>
          );
        })}
      </nav>
      <div className="border-t border-sidebar-border p-3">
        <Link href="/dashboard/venue" className="flex min-h-10 items-center gap-3 rounded-md px-3 text-sm text-white/50 hover:bg-white/[0.045] hover:text-white"><Settings className="size-4 text-white/34" />Settings</Link>
        <Link href="/venue/login" className="flex min-h-10 items-center gap-3 rounded-md px-3 text-sm text-white/50 hover:bg-white/[0.045] hover:text-white"><LogOut className="size-4 text-white/34" />Sign out</Link>
      </div>
      <div className="border-t border-sidebar-border p-4">
        <p className="text-sm font-medium">Demo Venue</p>
        <div className="mt-1 flex items-center gap-2 text-[11px] text-white/34"><span className="size-1.5 rounded-full bg-primary" />Approved · Free plan</div>
      </div>
    </>
  );
}

export function DashboardSidebar() {
  return <aside className="fixed inset-y-0 left-0 z-30 hidden w-60 flex-col border-r border-sidebar-border bg-sidebar lg:flex"><NavContent /></aside>;
}

export function DashboardMobileMenu() {
  return (
    <Sheet>
      <SheetTrigger render={<Button variant="outline" size="icon-lg" className="border-white/12 bg-transparent lg:hidden" aria-label="Open dashboard menu" />}><Menu className="size-5" /></SheetTrigger>
      <SheetContent side="left" className="w-[18rem] border-white/10 bg-sidebar p-0" showCloseButton={false}>
        <SheetHeader className="sr-only"><SheetTitle>Dashboard navigation</SheetTitle><SheetDescription>Choose a dashboard page</SheetDescription></SheetHeader>
        <NavContent />
      </SheetContent>
    </Sheet>
  );
}
