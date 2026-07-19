import Link from "next/link";
import { ArrowLeft, Info } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";

export default function NewOfferPage() {
  return (
    <div className="mx-auto max-w-3xl">
      <Link href="/dashboard/offers" className="inline-flex min-h-10 items-center gap-2 text-sm text-white/42 hover:text-white"><ArrowLeft className="size-4" />Offers</Link>
      <div className="mt-5"><p className="font-mono text-[10px] uppercase tracking-[0.17em] text-primary">New offer</p><h1 className="mt-2 text-3xl font-medium tracking-[-0.035em] sm:text-4xl">Create a check-in incentive</h1><p className="mt-2 text-sm text-white/40">Keep the value and staff instructions unmistakable.</p></div>

      <form action="/dashboard/offers" className="mt-9 space-y-7 rounded-lg border border-white/10 bg-card p-5 sm:p-7">
        <FormSection number="01" title="Guest-facing offer">
          <div className="space-y-2"><Label htmlFor="title">Offer</Label><Input id="title" name="title" placeholder="Free cover with Outly before 10 PM" required className="h-11 bg-white/[0.03]"/><p className="text-[11px] text-white/28">Use one short sentence. Avoid exclusions here.</p></div>
          <div className="space-y-2"><Label htmlFor="details">Details</Label><Textarea id="details" name="details" placeholder="Show the active offer screen to staff before 10 PM." className="min-h-24 bg-white/[0.03]"/></div>
        </FormSection>

        <FormSection number="02" title="Availability">
          <div className="grid gap-5 sm:grid-cols-2"><div className="space-y-2"><Label htmlFor="start-date">Start date</Label><Input id="start-date" name="start-date" type="date" required className="h-11 bg-white/[0.03]"/></div><div className="space-y-2"><Label htmlFor="end-date">End date</Label><Input id="end-date" name="end-date" type="date" required className="h-11 bg-white/[0.03]"/></div></div>
          <div className="grid gap-5 sm:grid-cols-2"><div className="space-y-2"><Label htmlFor="start-time">Starts</Label><Input id="start-time" name="start-time" type="time" required className="h-11 bg-white/[0.03]"/></div><div className="space-y-2"><Label htmlFor="end-time">Ends</Label><Input id="end-time" name="end-time" type="time" required className="h-11 bg-white/[0.03]"/></div></div>
          <div className="space-y-2"><Label>Eligible nights</Label><Select defaultValue="fri-sat" name="nights"><SelectTrigger className="h-11 w-full bg-white/[0.03]"><SelectValue /></SelectTrigger><SelectContent><SelectItem value="fri-sat">Friday and Saturday</SelectItem><SelectItem value="thu">Thursday</SelectItem><SelectItem value="daily">Every open night</SelectItem></SelectContent></Select></div>
        </FormSection>

        <FormSection number="03" title="Unlock rules">
          <div className="flex items-start justify-between gap-5"><div><Label htmlFor="check-in-required">Require verified check-in</Label><p className="mt-1 text-xs leading-5 text-white/34">Precise location must confirm the guest is within the venue geofence.</p></div><Switch id="check-in-required" defaultChecked disabled /></div>
          <div className="space-y-2"><Label>When can a guest check in?</Label><Select defaultValue="during" name="check-in-window"><SelectTrigger className="h-11 w-full bg-white/[0.03]"><SelectValue /></SelectTrigger><SelectContent><SelectItem value="during">During the offer window</SelectItem><SelectItem value="before">Up to 30 minutes before</SelectItem><SelectItem value="anytime">Any time tonight</SelectItem></SelectContent></Select></div>
          <div className="flex gap-2 border-l-2 border-primary/60 bg-primary/[0.035] p-4 text-xs leading-5 text-white/42"><Info className="mt-0.5 size-3.5 shrink-0 text-primary"/>After check-in, the guest gets 10 minutes to show the live offer screen to staff.</div>
        </FormSection>

        <div className="flex flex-col-reverse gap-3 border-t border-white/10 pt-6 sm:flex-row sm:justify-end"><Button variant="ghost" size="lg" render={<Link href="/dashboard/offers" />}>Cancel</Button><Button type="submit" size="lg">Save as draft</Button></div>
      </form>
    </div>
  );
}

function FormSection({number,title,children}:{number:string;title:string;children:React.ReactNode}) { return <section className="grid gap-5 border-b border-white/10 pb-7 last:border-b-0"><div className="flex items-center gap-3"><span className="font-mono text-[10px] text-primary">{number}</span><h2 className="font-medium">{title}</h2></div>{children}</section>; }
