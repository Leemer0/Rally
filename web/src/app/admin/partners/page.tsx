import Link from "next/link";
import { Building2, Plus } from "lucide-react";
import {
  AdminPageHeader,
  ConfirmationNotice,
  ErrorNotice,
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
import {
  getFounderDashboardSnapshot,
  presentStatus,
} from "@/lib/data/founder-dashboard";
import { cn } from "@/lib/utils";

type SearchParams = Promise<{ created?: string; error?: string }>;

export default async function AdminPartnersPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const [params, snapshot] = await Promise.all([
    searchParams,
    getFounderDashboardSnapshot(),
  ]);
  const campaignCount = snapshot.partners.reduce(
    (sum, partner) => sum + partner.campaignCount,
    0,
  );

  return (
    <div className="space-y-7">
      <AdminPageHeader
        title="Partners"
        description="Maintain approved sponsor records and launch partner-funded venue campaigns."
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
              Create campaign
            </Link>
          </div>
        }
      />

      {params.created === "partner" ? (
        <ConfirmationNotice>The partner record was created.</ConfirmationNotice>
      ) : null}
      {params.created === "offer" ? (
        <ConfirmationNotice>
          The partner campaign and venue offers were created.
        </ConfirmationNotice>
      ) : null}
      {params.error ? (
        <ErrorNotice>The partner operation failed. Review the inputs and try again.</ErrorNotice>
      ) : null}

      <section className="grid overflow-hidden rounded-lg border border-white/10 bg-card sm:grid-cols-3">
        <Metric label="Partner records" value={snapshot.partners.length} />
        <Metric
          label="Active partners"
          value={snapshot.partners.filter((partner) => partner.status === "active").length}
        />
        <Metric label="Campaigns" value={campaignCount} />
      </section>

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="border-b border-white/8 px-5 py-5 sm:px-6">
          <h2 className="font-medium">Partner records</h2>
          <p className="mt-1 text-xs text-white/38">
            Current approved identity and campaign counts from Supabase
          </p>
        </div>
        {snapshot.partners.length ? (
          <Table>
            <TableHeader>
              <TableRow className="border-white/8 hover:bg-transparent">
                <TableHead className="pl-5 sm:pl-6">Partner</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="hidden md:table-cell">Legal name</TableHead>
                <TableHead className="hidden lg:table-cell">Website</TableHead>
                <TableHead className="hidden sm:table-cell">Campaigns</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {snapshot.partners.map((partner) => (
                <TableRow key={partner.id} className="border-white/8">
                  <TableCell className="pl-5 sm:pl-6">
                    <p className="font-medium text-white/82">{partner.brandName}</p>
                    <p className="mt-0.5 font-mono text-[10px] text-white/30">
                      {partner.id.slice(0, 8)}
                    </p>
                  </TableCell>
                  <TableCell>
                    <StatusBadge status={presentStatus(partner.status)} />
                  </TableCell>
                  <TableCell className="hidden text-white/50 md:table-cell">
                    {partner.legalName}
                  </TableCell>
                  <TableCell className="hidden lg:table-cell">
                    {partner.websiteUrl ? (
                      <a
                        href={partner.websiteUrl}
                        target="_blank"
                        rel="noreferrer"
                        className="text-white/54 hover:text-primary"
                      >
                        Visit site
                      </a>
                    ) : (
                      <span className="text-white/34">Not set</span>
                    )}
                  </TableCell>
                  <TableCell className="numeric hidden font-mono sm:table-cell">
                    {partner.campaignCount}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        ) : (
          <div className="px-5 py-16 text-center">
            <p className="font-medium">No partner records yet</p>
            <p className="mx-auto mt-2 max-w-sm text-sm text-white/42">
              Create the partner identity before launching a funded campaign.
            </p>
            <Link
              href="/admin/partners/new?mode=partner"
              className={cn(
                buttonVariants({ variant: "outline" }),
                "mt-5 h-11 border-white/12",
              )}
            >
              Add first partner
            </Link>
          </div>
        )}
      </section>
    </div>
  );
}

function Metric({ label, value }: { label: string; value: number }) {
  return (
    <div className="border-b border-white/10 p-5 last:border-b-0 sm:border-b-0 sm:border-r sm:last:border-r-0">
      <p className="text-xs text-white/42">{label}</p>
      <p className="numeric mt-3 font-mono text-3xl font-medium">{value}</p>
    </div>
  );
}
