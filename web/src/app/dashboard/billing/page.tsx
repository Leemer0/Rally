import { Check, CreditCard, ExternalLink } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

const paidFeatures = ["Advanced attendance analytics", "Featured discovery placement", "More active offers", "Campaign targeting controls", "Partner campaign matching"];

export default function BillingPage() {
  return (
    <div className="space-y-8">
      <div><p className="font-mono text-[10px] uppercase tracking-[0.17em] text-primary">Plan &amp; billing</p><h1 className="mt-2 text-3xl font-medium tracking-[-0.035em] sm:text-4xl">Your venue plan</h1><p className="mt-2 text-sm text-white/40">Manage access and, once connected, Stripe billing.</p></div>

      <section className="grid overflow-hidden rounded-lg border border-white/10 bg-card lg:grid-cols-[.72fr_1.28fr]">
        <div className="border-b border-white/10 p-6 lg:border-b-0 lg:border-r lg:p-8">
          <div className="flex items-center justify-between"><p className="font-mono text-[10px] uppercase tracking-[.17em] text-white/38">Current plan</p><Badge variant="outline" className="rounded-sm border-white/12">Free</Badge></div>
          <p className="mt-8 text-5xl font-medium tracking-[-0.055em]">C$0</p>
          <p className="mt-3 text-sm text-white/38">No payment method required.</p>
          <div className="mt-8 space-y-3 text-sm text-white/56">{["Basic listing", "Basic offer creation", "Limited analytics"].map(item=><p key={item} className="flex gap-2"><Check className="size-4 text-primary"/>{item}</p>)}</div>
        </div>
        <div className="bg-[#11161d] p-6 lg:p-8">
          <div className="flex flex-col justify-between gap-4 sm:flex-row"><div><p className="font-mono text-[10px] uppercase tracking-[.17em] text-primary">Paid plan</p><h2 className="mt-3 text-2xl font-medium">Outly Pro</h2></div><p className="numeric text-3xl font-medium">C$129<span className="text-sm font-normal text-white/34">/month</span></p></div>
          <div className="mt-7 grid gap-3 sm:grid-cols-2">{paidFeatures.map(item=><p key={item} className="flex gap-2 text-sm text-white/56"><Check className="size-4 text-primary"/>{item}</p>)}</div>
          <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:items-center"><Button size="lg">Request upgrade</Button><p className="text-[11px] leading-5 text-white/28">Final pricing and limits will be confirmed before billing begins.</p></div>
        </div>
      </section>

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="flex items-center justify-between p-5 sm:p-6"><div><h2 className="font-medium">Billing history</h2><p className="mt-1 text-xs text-white/34">Invoices will appear after Stripe is connected.</p></div><CreditCard className="size-4 text-white/28"/></div>
        <Table><TableHeader><TableRow className="border-white/8"><TableHead>Date</TableHead><TableHead>Description</TableHead><TableHead>Amount</TableHead><TableHead><span className="sr-only">Invoice</span></TableHead></TableRow></TableHeader><TableBody><TableRow className="border-white/8"><TableCell colSpan={4} className="h-28 text-center text-sm text-white/32">No invoices yet.</TableCell></TableRow></TableBody></Table>
      </section>

      <div className="flex items-center gap-2 text-[11px] text-white/28"><ExternalLink className="size-3"/>Stripe customer portal will be linked here after backend setup.</div>
    </div>
  );
}
