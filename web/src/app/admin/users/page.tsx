import Link from "next/link";
import { Search } from "lucide-react";
import {
  AdminPageHeader,
  AdminSelect,
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
import {
  formatAdminDate,
  getFounderDashboardSnapshot,
  maskEmail,
  presentStatus,
} from "@/lib/data/founder-dashboard";
import { cn } from "@/lib/utils";

type SearchParams = Promise<{
  q?: string;
  status?: string;
}>;

export default async function AdminUsersPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const [params, snapshot] = await Promise.all([
    searchParams,
    getFounderDashboardSnapshot(),
  ]);
  const query = params.q?.trim().toLowerCase() ?? "";
  const status = params.status ?? "all";
  const filteredUsers = snapshot.consumers.filter((user) => {
    const matchesQuery =
      !query ||
      user.userId.toLowerCase().includes(query) ||
      user.email?.toLowerCase().includes(query) ||
      user.firstName?.toLowerCase().includes(query);
    const matchesStatus = status === "all" || user.accountStatus === status;
    return matchesQuery && matchesStatus;
  });

  return (
    <div className="space-y-7">
      <AdminPageHeader
        title="Users"
        description="Search consumer account state without exposing dates of birth or location evidence."
      />

      <section className="overflow-hidden rounded-lg border border-white/10 bg-card">
        <form
          action="/admin/users"
          method="get"
          className="flex flex-col gap-3 border-b border-white/10 p-4 sm:flex-row"
          role="search"
        >
          <div className="relative flex-1">
            <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-white/34" />
            <Input
              type="search"
              name="q"
              defaultValue={params.q}
              aria-label="Search users"
              placeholder="Search user ID, name, or email"
              className="h-11 bg-white/[0.025] pl-9"
            />
          </div>
          <AdminSelect id="user-status" name="status" defaultValue={status}>
            <option value="all">All statuses</option>
            <option value="active">Active</option>
            <option value="suspended">Suspended</option>
            <option value="deletion_pending">Deletion pending</option>
            <option value="deleted">Deleted</option>
          </AdminSelect>
          <button
            type="submit"
            className={cn(
              buttonVariants({ variant: "secondary", size: "lg" }),
              "h-11 px-4",
            )}
          >
            Apply filters
          </button>
          {(query || status !== "all") && (
            <Link
              href="/admin/users"
              className={cn(
                buttonVariants({ variant: "ghost", size: "lg" }),
                "h-11 px-3",
              )}
            >
              Clear
            </Link>
          )}
        </form>

        {filteredUsers.length ? (
          <>
            <Table>
              <TableHeader>
                <TableRow className="border-white/8 hover:bg-transparent">
                  <TableHead className="pl-5 sm:pl-6">User</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="hidden sm:table-cell">Onboarding</TableHead>
                  <TableHead className="hidden md:table-cell">First name</TableHead>
                  <TableHead className="hidden lg:table-cell">Joined</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredUsers.map((user) => (
                  <TableRow key={user.userId} className="border-white/8">
                    <TableCell className="pl-5 sm:pl-6">
                      <p className="font-mono text-xs font-medium text-white/82">
                        {user.userId.slice(0, 8)}
                      </p>
                      <p className="mt-0.5 text-[11px] text-white/36">
                        {maskEmail(user.email)}
                      </p>
                    </TableCell>
                    <TableCell>
                      <StatusBadge status={presentStatus(user.accountStatus)} />
                    </TableCell>
                    <TableCell className="hidden text-white/54 sm:table-cell">
                      {presentStatus(user.onboardingStatus)}
                    </TableCell>
                    <TableCell className="hidden text-white/54 md:table-cell">
                      {user.firstName || "Not provided"}
                    </TableCell>
                    <TableCell className="hidden text-white/50 lg:table-cell">
                      {formatAdminDate(user.createdAt)}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
            <div className="border-t border-white/8 px-5 py-3 text-[11px] text-white/34">
              {filteredUsers.length} of {snapshot.consumers.length} recent consumer records shown
            </div>
          </>
        ) : (
          <div className="px-5 py-16 text-center">
            <p className="font-medium">No users match these filters</p>
            <p className="mx-auto mt-2 max-w-sm text-sm text-white/42">
              Try another user ID, name, masked email, or account status.
            </p>
            <Link
              href="/admin/users"
              className={cn(
                buttonVariants({ variant: "outline" }),
                "mt-5 h-11 border-white/12",
              )}
            >
              Reset filters
            </Link>
          </div>
        )}
      </section>

      <p className="max-w-3xl text-[11px] leading-5 text-white/34">
        The operational list intentionally omits date of birth, gender, and precise
        check-in evidence. Account deletion remains a separate audited workflow.
      </p>
    </div>
  );
}
