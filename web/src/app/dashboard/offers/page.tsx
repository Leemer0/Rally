import Link from "next/link";
import { MoreHorizontal, Plus } from "lucide-react";
import { offers } from "@/lib/demo-data";
import { Badge } from "@/components/ui/badge";
import { Button, buttonVariants } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { cn } from "@/lib/utils";

export default function OffersPage() {
  return (
    <div className="space-y-8">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div><p className="font-mono text-[10px] uppercase tracking-[0.17em] text-primary">Offers</p><h1 className="mt-2 text-3xl font-medium tracking-[-0.035em] sm:text-4xl">Check-in incentives</h1><p className="mt-2 text-sm text-white/40">Create offers guests can unlock after a verified arrival.</p></div>
        <Link href="/dashboard/offers/new" className={cn(buttonVariants({ size: "lg" }), "h-11 px-4")}><Plus className="size-4" />Create offer</Link>
      </div>

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <Table>
          <TableHeader><TableRow className="border-white/8 hover:bg-transparent"><TableHead>Offer</TableHead><TableHead>Status</TableHead><TableHead className="hidden md:table-cell">Availability</TableHead><TableHead className="hidden sm:table-cell">Unlocked</TableHead><TableHead><span className="sr-only">Actions</span></TableHead></TableRow></TableHeader>
          <TableBody>
            {offers.map((offer) => <TableRow key={offer.name} className="border-white/8"><TableCell><p className="font-medium text-white/82">{offer.name}</p><p className="mt-1 text-[11px] text-white/28 md:hidden">{offer.window}</p></TableCell><TableCell><Badge variant="outline" className={cn("rounded-sm", offer.status === 'Active' ? 'border-primary/25 text-primary' : 'border-white/12 text-white/42')}>{offer.status}</Badge></TableCell><TableCell className="hidden text-white/42 md:table-cell">{offer.window}</TableCell><TableCell className="numeric hidden sm:table-cell">{offer.unlocked}</TableCell><TableCell className="text-right"><Button variant="ghost" size="icon-sm" aria-label={`Options for ${offer.name}`}><MoreHorizontal /></Button></TableCell></TableRow>)}
          </TableBody>
        </Table>
        <div className="border-t border-white/8 px-5 py-4 text-[11px] text-white/28">2 offers · Free plan limit is provisional until launch rules are approved.</div>
      </section>

      <section className="grid gap-5 md:grid-cols-3">
        <OfferPrinciple number="01" title="Clear value" copy="Staff and guests should understand the offer in one glance." />
        <OfferPrinciple number="02" title="Defined window" copy="Use a narrow availability window to drive a specific part of the night." />
        <OfferPrinciple number="03" title="Verified arrival" copy="The offer only appears after the app confirms the venue geofence." />
      </section>
    </div>
  );
}

function OfferPrinciple({number,title,copy}:{number:string;title:string;copy:string}) { return <div className="border-t border-white/12 pt-5"><p className="font-mono text-[10px] text-primary">{number}</p><h2 className="mt-5 font-medium">{title}</h2><p className="mt-2 text-sm leading-6 text-white/38">{copy}</p></div>; }
