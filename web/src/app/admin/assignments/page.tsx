import Link from "next/link";
import { Send } from "lucide-react";
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
import { assignments } from "@/lib/admin-demo-data";
import { cn } from "@/lib/utils";

type SearchParams = Promise<{ assigned?: string }>;

export default async function AdminAssignmentsPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const params = await searchParams;
  const activeCount = assignments.filter((item) => item.status === "Active").length;
  const claimCount = assignments.reduce((sum, item) => sum + item.claims, 0);

  return (
    <div className="space-y-7">
      <AdminPageHeader
        title="Offer assignments"
        description="Send approved partner offers to selected venues and track acceptance."
        action={
          <Link
            href="/admin/assignments/new"
            className={cn(buttonVariants({ size: "lg" }), "h-11 px-4")}
          >
            <Send className="size-4" />
            New assignment
          </Link>
        }
      />

      {params.assigned === "1" ? (
        <ConfirmationNotice>
          Prototype assignment received. No venue was contacted and nothing was saved.
        </ConfirmationNotice>
      ) : null}
      <DemoNotice />

      <section className="grid overflow-hidden rounded-lg border border-white/10 bg-card sm:grid-cols-3">
        <Metric label="Active placements" value={String(activeCount)} note="Across 3 venues" />
        <Metric label="Awaiting venue" value="1" note="No reminder sent" />
        <Metric label="Partner claims" value={String(claimCount)} note="Current demo campaigns" />
      </section>

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <div className="border-b border-white/8 px-5 py-5 sm:px-6">
          <h2 className="font-medium">Assignment log</h2>
          <p className="mt-1 text-xs text-white/38">
            One row per offer and venue pairing
          </p>
        </div>
        <Table>
          <TableHeader>
            <TableRow className="border-white/8 hover:bg-transparent">
              <TableHead className="pl-5 sm:pl-6">Assignment</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="hidden md:table-cell">Venue</TableHead>
              <TableHead className="hidden lg:table-cell">Window</TableHead>
              <TableHead className="hidden sm:table-cell">Claims</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {assignments.map((assignment) => (
              <TableRow key={assignment.id} className="border-white/8">
                <TableCell className="pl-5 sm:pl-6">
                  <p className="font-medium text-white/82">{assignment.offer}</p>
                  <p className="mt-0.5 text-[11px] text-white/36">
                    {assignment.id} · {assignment.partner}
                  </p>
                </TableCell>
                <TableCell><StatusBadge status={assignment.status} /></TableCell>
                <TableCell className="hidden text-white/56 md:table-cell">{assignment.venue}</TableCell>
                <TableCell className="hidden text-white/50 lg:table-cell">{assignment.window}</TableCell>
                <TableCell className="numeric hidden font-mono sm:table-cell">{assignment.claims}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </section>
    </div>
  );
}

function Metric({ label, value, note }: { label: string; value: string; note: string }) {
  return (
    <div className="border-b border-white/10 p-5 last:border-b-0 sm:border-b-0 sm:border-r sm:last:border-r-0">
      <p className="text-xs text-white/42">{label}</p>
      <p className="numeric mt-3 font-mono text-3xl font-medium">{value}</p>
      <p className="mt-1.5 text-[11px] text-white/34">{note}</p>
    </div>
  );
}
