import Image from "next/image";
import { ExternalLink, MapPin, ShieldCheck } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";

const hours = [
  ["Monday", "Closed"],
  ["Tuesday", "5:00 PM–2:00 AM"],
  ["Wednesday", "5:00 PM–2:00 AM"],
  ["Thursday", "5:00 PM–2:00 AM"],
  ["Friday", "5:00 PM–2:00 AM"],
  ["Saturday", "5:00 PM–2:00 AM"],
  ["Sunday", "5:00 PM–2:00 AM"],
];

export default function VenueProfilePage() {
  return (
    <div className="space-y-8">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
        <div><p className="font-mono text-[10px] uppercase tracking-[0.17em] text-primary">Venue profile</p><h1 className="mt-2 text-3xl font-medium tracking-[-0.035em] sm:text-4xl">Demo Venue</h1><p className="mt-2 text-sm text-white/40">The public details shown in Outly discovery.</p></div>
        <Button size="lg" className="h-11">Save changes</Button>
      </div>

      <div className="grid gap-5 xl:grid-cols-[1.1fr_.9fr]">
        <form className="space-y-7 rounded-lg border border-white/10 bg-card p-5 sm:p-7">
          <div className="flex items-center justify-between border-b border-white/10 pb-5"><div><h2 className="font-medium">Listing details</h2><p className="mt-1 text-xs text-white/34">Edits may be reviewed before publishing.</p></div><Badge variant="outline" className="rounded-sm border-primary/25 text-primary"><ShieldCheck className="size-3"/>Approved</Badge></div>
          <div className="grid gap-5 sm:grid-cols-2"><Field id="display-name" label="Venue name" value="Demo Venue"/><Field id="neighbourhood" label="Neighbourhood" value="Ossington"/></div>
          <div className="space-y-2"><Label htmlFor="address">Address</Label><div className="relative"><MapPin className="absolute left-3 top-3.5 size-4 text-primary"/><Input id="address" defaultValue="Toronto, Ontario" className="h-11 bg-white/[0.03] pl-10"/></div><a href="https://maps.apple.com/?q=Toronto%20Ontario" target="_blank" rel="noreferrer" className="inline-flex items-center gap-1 text-[11px] text-white/36 hover:text-white">Open in Maps <ExternalLink className="size-3"/></a></div>
          <div className="grid gap-5 sm:grid-cols-2"><Field id="contact-email" label="Business email" value="venue@example.com" type="email"/><Field id="contact-phone" label="Business phone" value="(416) 555-0100" type="tel"/></div>
          <div className="flex items-start justify-between gap-4 border-t border-white/10 pt-6"><div><Label htmlFor="visible">Visible in discovery</Label><p className="mt-1 text-xs leading-5 text-white/34">Temporarily hide the venue without deleting its account.</p></div><Switch id="visible" defaultChecked/></div>
        </form>

        <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
          <div className="relative h-56"><Image src="/brand/nightlife.png" alt="Anonymous demo venue preview" fill sizes="(max-width: 1280px) 100vw, 35vw" className="object-cover object-center opacity-75"/><div className="absolute inset-0 bg-gradient-to-t from-card via-transparent to-transparent"/></div>
          <div className="p-5 sm:p-6"><p className="font-mono text-[9px] uppercase tracking-[.16em] text-primary">App preview</p><h2 className="mt-3 text-2xl font-medium">Demo Venue</h2><p className="mt-1 text-sm text-white/42">Ossington</p><div className="mt-5 flex items-center justify-between border-t border-white/8 pt-4 text-xs"><span className="text-white/38">Open tonight</span><span>5:00 PM-2:00 AM</span></div></div>
        </section>
      </div>

      <section className="rounded-lg border border-white/10 bg-card p-5 sm:p-7">
        <div><h2 className="font-medium">Hours</h2><p className="mt-1 text-xs text-white/34">Local venue time · America/Toronto</p></div>
        <div className="mt-6 divide-y divide-white/8 border-y border-white/8">
          {hours.map(([day,value]) => <div key={day} className="grid grid-cols-[7rem_1fr] items-center gap-4 py-3"><Label htmlFor={`hours-${day}`} className="text-white/48">{day}</Label><Input id={`hours-${day}`} defaultValue={value} className="h-9 max-w-sm bg-white/[0.025]"/></div>)}
        </div>
      </section>

      <section className="rounded-lg border border-destructive/25 bg-destructive/[0.035] p-5 sm:p-7">
        <h2 className="font-medium">Delete venue account</h2><p className="mt-2 max-w-2xl text-sm leading-6 text-white/40">Account deletion will remove dashboard access and start the venue-data deletion process. This action will require password confirmation when backend authentication is connected.</p><Button variant="destructive" className="mt-5">Request account deletion</Button>
      </section>
    </div>
  );
}

function Field({id,label,value,type='text'}:{id:string;label:string;value:string;type?:string}) { return <div className="space-y-2"><Label htmlFor={id}>{label}</Label><Input id={id} type={type} defaultValue={value} className="h-11 bg-white/[0.03]"/></div>; }
