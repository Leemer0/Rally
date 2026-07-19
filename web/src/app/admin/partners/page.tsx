import Link from "next/link";
import { Building2, Plus } from "lucide-react";
import {
  AdminPageHeader,
  ConfirmationNotice,
  DemoNotice,
  StatusBadge,
} from "@/components/admin/admin-ui";
import { buttonVariants } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { partnerOffers, partners } from "@/lib/admin-demo-data";
import { cn } from "@/lib/utils";

type SearchParams = Promise<{ created?: string }>;

export default async function AdminPartnersPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const params = await searchParams;

  return (
    <div className="space-y-7">
      <AdminPageHeader
        title="Partners"
        description="Maintain sponsor records, define partner-funded offers, and track rollout readiness."
        action={
          <div className="flex gap-2">
            <Link
              href="/admin/partners/new?mode=partner"
              className={cn(
                buttonVariants({ variant: "outline", size: "lg" }),
                "h-11 border-white/12 px-4",
              )}
            >
              <Building2 className="size-4" />
              Add partner
            </Link>
            <Link
              href="/admin/partners/new?mode=offer"
              className={cn(buttonVariants({ size: "lg" }), "h-11 px-4")}
            >
              <Plus className="size-4" />
              Create offer
            </Link>
          </div>
        }
      />

      {params.created ? (
        <ConfirmationNotice>
          Prototype {params.created} submission received. Nothing was saved.
        </ConfirmationNotice>
      ) : null}
      <DemoNotice />

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="border-b border-white/8 px-5 py-5 sm:px-6">
          <h2 className="font-medium">Partner records</h2>
          <p className="mt-1 text-xs text-white/38">
            Commercial contact, funding envelope, and account state
          </p>
        </div>
        <Table>
          <TableHeader>
            <TableRow className="border-white/8 hover:bg-transparent">
              <TableHead className="pl-5 sm:pl-6">Partner</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="hidden md:table-cell">Contact</TableHead>
              <TableHead className="hidden sm:table-cell">Offers</TableHead>
              <TableHead className="hidden lg:table-cell">Demo budget</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {partners.map((partner) => (
              <TableRow key={partner.id} className="border-white/8">
                <TableCell className="pl-5 sm:pl-6">
                  <p className="font-medium text-white/82">{partner.name}</p>
                  <p className="mt-0.5 text-[11px] text-white/36">{partner.category}</p>
                </TableCell>
                <TableCell><StatusBadge status={partner.status} /></TableCell>
                <TableCell className="hidden text-white/50 md:table-cell">{partner.contact}</TableCell>
                <TableCell className="numeric hidden font-mono sm:table-cell">{partner.offers}</TableCell>
                <TableCell className="numeric hidden font-mono lg:table-cell">{partner.budget}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </section>

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="flex items-start justify-between gap-4 border-b border-white/8 px-5 py-5 sm:px-6">
          <div>
            <h2 className="font-medium">Partner offers</h2>
            <p className="mt-1 text-xs text-white/38">
              Funding terms and venue distribution are managed separately
            </p>
          </div>
          <Link
            href="/admin/assignments/new"
            className="inline-flex min-h-11 shrink-0 items-center text-xs text-white/48 transition-colors hover:text-white"
          >
            Assign to venues
          </Link>
        </div>
        <Table>
          <TableHeader>
            <TableRow className="border-white/8 hover:bg-transparent">
              <TableHead className="pl-5 sm:pl-6">Offer</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="hidden lg:table-cell">Unlock rule</TableHead>
              <TableHead className="hidden sm:table-cell">Venues</TableHead>
              <TableHead className="hidden md:table-cell">Claims</TableHead>
              <TableHead className="hidden xl:table-cell">Ends</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {partnerOffers.map((offer) => (
              <TableRow key={offer.id} className="border-white/8">
                <TableCell className="pl-5 sm:pl-6">
                  <p className="font-medium text-white/82">{offer.name}</p>
                  <p className="mt-0.5 text-[11px] text-white/36">{offer.partner}</p>
                </TableCell>
                <TableCell><StatusBadge status={offer.status} /></TableCell>
                <TableCell className="hidden text-white/50 lg:table-cell">{offer.claim}</TableCell>
                <TableCell className="numeric hidden font-mono sm:table-cell">{offer.venues}</TableCell>
                <TableCell className="numeric hidden font-mono md:table-cell">{offer.claims}</TableCell>
                <TableCell className="hidden text-white/50 xl:table-cell">{offer.ends}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </section>
    </div>
  );
}
