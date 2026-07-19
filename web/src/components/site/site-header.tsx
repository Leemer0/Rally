"use client";

import Link from "next/link";
import { Menu } from "lucide-react";
import { BrandMark } from "@/components/brand/mark";
import { Button, buttonVariants } from "@/components/ui/button";
import {
  Sheet,
  SheetClose,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { cn } from "@/lib/utils";

type SiteHeaderProps = {
  audience?: "consumer" | "venue";
};

export function SiteHeader({ audience = "consumer" }: SiteHeaderProps) {
  const venue = audience === "venue";
  const links = venue
    ? [
        { href: "/venues#product", label: "Product" },
        { href: "/venues#pricing", label: "Pricing" },
        { href: "/venues#faq", label: "Questions" },
      ]
    : [
        { href: "/#the-app", label: "The app" },
        { href: "/#how-it-works", label: "How it works" },
      ];

  return (
    <header className="absolute inset-x-0 top-0 z-40">
      <a
        href="#main-content"
        className="sr-only fixed left-4 top-4 z-[100] rounded-md bg-primary px-4 py-3 font-medium text-primary-foreground focus:not-sr-only"
      >
        Skip to content
      </a>
      <div className="mx-auto flex h-20 w-full max-w-[90rem] items-center justify-between px-5 sm:px-8 lg:px-12">
        <Link href={venue ? "/venues" : "/"} aria-label="Outly home" className="flex items-center gap-3">
          <BrandMark />
          {venue ? (
            <span className="border-l border-white/20 pl-3 text-sm text-white/65">For venues</span>
          ) : null}
        </Link>

        <nav className="hidden items-center gap-8 text-sm text-white/66 md:flex" aria-label="Primary navigation">
          {links.map((link) => (
            <Link key={link.href} href={link.href} className="transition-colors hover:text-white">
              {link.label}
            </Link>
          ))}
        </nav>

        <div className="hidden items-center gap-2 md:flex">
          {venue ? (
            <>
              <Link href="/venue/login" className={cn(buttonVariants({ variant: "ghost", size: "lg" }), "h-11 px-4 text-white/78 hover:bg-white/7 hover:text-white")}>Sign in</Link>
              <Link href="/venue/register" className={cn(buttonVariants({ size: "lg" }), "h-11 px-5")}>Get Started</Link>
            </>
          ) : (
            <Link href="/venues" className={cn(buttonVariants({ variant: "outline", size: "lg" }), "h-11 border-white/16 bg-black/18 px-5 text-white hover:bg-white/8")}>For venues</Link>
          )}
        </div>

        <Sheet>
          <SheetTrigger render={<Button variant="outline" size="icon-lg" className="border-white/14 bg-black/25 text-white md:hidden" aria-label="Open menu" />}>
            <Menu className="size-5" />
          </SheetTrigger>
          <SheetContent className="border-white/10 bg-[#0c1016] p-0" side="right">
            <SheetHeader className="border-b border-white/10 p-6">
              <BrandMark />
              <SheetTitle className="sr-only">Navigation</SheetTitle>
              <SheetDescription className="sr-only">Choose a page</SheetDescription>
            </SheetHeader>
            <nav className="flex flex-col p-3" aria-label="Mobile navigation">
              {links.map((link) => (
                <SheetClose key={link.href} render={<Link href={link.href} className="flex min-h-12 items-center border-b border-white/8 px-3 text-lg text-white" />}>
                  {link.label}
                </SheetClose>
              ))}
            </nav>
            <div className="mt-auto grid gap-3 p-6">
              {venue ? (
                <>
                  <SheetClose render={<Link href="/venue/register" className={cn(buttonVariants({ size: "lg" }), "h-12")} />}>Get Started</SheetClose>
                  <SheetClose render={<Link href="/venue/login" className={cn(buttonVariants({ variant: "outline", size: "lg" }), "h-12")} />}>Sign in</SheetClose>
                </>
              ) : (
                <SheetClose render={<Link href="/venues" className={cn(buttonVariants({ size: "lg" }), "h-12")} />}>For venues</SheetClose>
              )}
            </div>
          </SheetContent>
        </Sheet>
      </div>
    </header>
  );
}
