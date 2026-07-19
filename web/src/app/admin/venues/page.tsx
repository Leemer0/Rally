import Link from "next/link";
import { Plus, Search } from "lucide-react";
import {
  AdminPageHeader,
  AdminSelect,
  ConfirmationNotice,
  DemoNotice,
  StatusBadge,
} from "@/components/admin/admin-ui";
import { Input } from "@/components/ui/input";
import { buttonVariants } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { venues } from "@/lib/admin-demo-data";
import { cn } from "@/lib/utils";

type SearchParams = Promise<{
  q?: string;
  status?: string;
  created?: string;
}>;

export default async function AdminVenuesPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const params = await searchParams;
  const query = params.q?.trim().toLowerCase() ?? "";
  const status = params.status ?? "all";
  const filteredVenues = venues.filter((venue) => {
    const matchesQuery =
      !query ||
      venue.name.toLowerCase().includes(query) ||
      venue.neighborhood.toLowerCase().includes(query);
    const matchesStatus = status === "all" || venue.status.toLowerCase() === status;
    return matchesQuery && matchesStatus;
  });

  return (
    <div className="space-y-7">
      <AdminPageHeader
        title="Venues"
        description="Add listings, review self-registrations, and monitor venue performance."
        action={
          <Link
            href="/admin/venues/new"
            className={cn(buttonVariants({ size: "lg" }), "h-11 px-4")}
          >
            <Plus className="size-4" />
            Add venue
          </Link>
        }
      />

      {params.created === "1" ? (
        <ConfirmationNotice>
          Prototype submission received. No venue record was saved.
        </ConfirmationNotice>
      ) : null}
      <DemoNotice />

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <form
          action="/admin/venues"
          method="get"
          className="flex flex-col gap-3 border-b border-white/10 p-4 sm:flex-row sm:items-center"
          role="search"
        >
          <div className="relative flex-1">
            <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-white/34" />
            <Input
              type="search"
              name="q"
              defaultValue={params.q}
              aria-label="Search venues"
              placeholder="Search name or neighborhood"
              className="h-11 bg-white/[0.025] pl-9"
            />
          </div>
          <AdminSelect
            id="venue-status"
            name="status"
            defaultValue={status}
          >
            <option value="all">All statuses</option>
            <option value="approved">Approved</option>
            <option value="pending">Pending</option>
            <option value="paused">Paused</option>
          </AdminSelect>
          <button
            type="submit"
            className={cn(buttonVariants({ variant: "secondary", size: "lg" }), "h-11 px-4")}
          >
            Apply filters
          </button>
          {(query || status !== "all") && (
            <Link
              href="/admin/venues"
              className={cn(
                buttonVariants({ variant: "ghost", size: "lg" }),
                "h-11 px-3",
              )}
            >
              Clear
            </Link>
          )}
        </form>

        {filteredVenues.length ? (
          <>
            <Table>
              <TableHeader>
                <TableRow className="border-white/8 hover:bg-transparent">
                  <TableHead className="pl-5">Venue</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="hidden lg:table-cell">Plan</TableHead>
                  <TableHead className="hidden sm:table-cell">Tonight</TableHead>
                  <TableHead className="hidden md:table-cell">30-day check-ins</TableHead>
                  <TableHead className="hidden xl:table-cell">Repeat</TableHead>
                  <TableHead className="pr-5 text-right">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredVenues.map((venue) => (
                  <TableRow key={venue.id} className="border-white/8">
                    <TableCell className="pl-5">
                      <p className="font-medium text-white/82">{venue.name}</p>
                      <p className="mt-0.5 text-[11px] text-white/36">
                        {venue.neighborhood}
                      </p>
                    </TableCell>
                    <TableCell><StatusBadge status={venue.status} /></TableCell>
                    <TableCell className="hidden text-white/54 lg:table-cell">
                      {venue.plan}
                    </TableCell>
                    <TableCell className="numeric hidden font-mono sm:table-cell">
                      {venue.tonight}
                    </TableCell>
                    <TableCell className="numeric hidden font-mono md:table-cell">
                      {venue.checkIns30d}
                    </TableCell>
                    <TableCell className="numeric hidden font-mono xl:table-cell">
                      {venue.repeatRate}
                    </TableCell>
                    <TableCell className="pr-5 text-right">
                      <Link
                        href={`/admin/venues/${venue.id}`}
                        className={cn(
                          buttonVariants({ variant: "ghost", size: "sm" }),
                          "h-11 text-white/64",
                        )}
                      >
                        Review
                      </Link>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
            <div className="border-t border-white/8 px-5 py-3 text-[11px] text-white/34">
              Showing {filteredVenues.length} of {venues.length} fictional venues
            </div>
          </>
        ) : (
          <div className="px-5 py-16 text-center">
            <p className="font-medium">No venues match these filters</p>
            <p className="mx-auto mt-2 max-w-sm text-sm text-white/42">
              Try a different name, neighborhood, or approval status.
            </p>
            <Link
              href="/admin/venues"
              className={cn(buttonVariants({ variant: "outline" }), "mt-5 h-11 border-white/12")}
            >
              Reset filters
            </Link>
          </div>
        )}
      </section>
    </div>
  );
}
