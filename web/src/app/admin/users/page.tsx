import Link from "next/link";
import { Check, Search } from "lucide-react";
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
import { users } from "@/lib/admin-demo-data";
import { cn } from "@/lib/utils";

type SearchParams = Promise<{
  q?: string;
  status?: string;
  action?: string;
}>;

export default async function AdminUsersPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const params = await searchParams;
  const query = params.q?.trim().toLowerCase() ?? "";
  const status = params.status ?? "all";
  const filteredUsers = users.filter((user) => {
    const matchesQuery =
      !query ||
      user.id.toLowerCase().includes(query) ||
      user.email.toLowerCase().includes(query);
    const matchesStatus = status === "all" || user.status.toLowerCase() === status;
    return matchesQuery && matchesStatus;
  });

  return (
    <div className="space-y-7">
      <AdminPageHeader
        title="Users"
        description="Search anonymous user records, review account state, and process deletion requests."
      />

      {params.action ? (
        <ConfirmationNotice>
          Prototype action “{params.action}” received. No user account was changed.
        </ConfirmationNotice>
      ) : null}
      <DemoNotice message="Fictional, masked user data. Dates of birth are not displayed in this operational list." />

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
              placeholder="Search user ID or masked email"
              className="h-11 bg-white/[0.025] pl-9"
            />
          </div>
          <AdminSelect id="user-status" name="status" defaultValue={status}>
            <option value="all">All statuses</option>
            <option value="active">Active</option>
            <option value="paused">Paused</option>
            <option value="deletion requested">Deletion requested</option>
          </AdminSelect>
          <button
            type="submit"
            className={cn(buttonVariants({ variant: "secondary", size: "lg" }), "h-11 px-4")}
          >
            Apply filters
          </button>
          {(query || status !== "all") && (
            <Link
              href="/admin/users"
              className={cn(buttonVariants({ variant: "ghost", size: "lg" }), "h-11 px-3")}
            >
              Clear
            </Link>
          )}
        </form>

        <form action="/admin/users" method="get">
          {filteredUsers.length ? (
            <>
              <Table>
                <TableHeader>
                  <TableRow className="border-white/8 hover:bg-transparent">
                    <TableHead className="w-12 pl-5">
                      <span className="sr-only">Select users</span>
                    </TableHead>
                    <TableHead>User</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>19+</TableHead>
                    <TableHead className="hidden lg:table-cell">Gender</TableHead>
                    <TableHead className="hidden sm:table-cell">Plans</TableHead>
                    <TableHead className="hidden md:table-cell">Check-ins</TableHead>
                    <TableHead className="hidden xl:table-cell">Last active</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredUsers.map((user) => (
                    <TableRow key={user.id} className="border-white/8">
                      <TableCell className="pl-5">
                        <label className="flex size-11 cursor-pointer items-center justify-center">
                          <span className="sr-only">Select {user.id}</span>
                          <input
                            type="checkbox"
                            name="selected"
                            value={user.id}
                            className="size-4 rounded border-white/18 accent-[var(--primary)]"
                          />
                        </label>
                      </TableCell>
                      <TableCell>
                        <p className="font-mono text-xs font-medium text-white/82">{user.id}</p>
                        <p className="mt-0.5 text-[11px] text-white/36">{user.email}</p>
                      </TableCell>
                      <TableCell><StatusBadge status={user.status} /></TableCell>
                      <TableCell>
                        {user.is19Plus ? (
                          <span className="inline-flex items-center gap-1.5 text-xs text-white/64">
                            <Check className="size-3.5 text-primary" /> Yes
                          </span>
                        ) : (
                          <span className="text-xs text-white/48">No</span>
                        )}
                      </TableCell>
                      <TableCell className="hidden text-white/54 lg:table-cell">{user.gender}</TableCell>
                      <TableCell className="numeric hidden font-mono sm:table-cell">{user.plans}</TableCell>
                      <TableCell className="numeric hidden font-mono md:table-cell">{user.checkIns}</TableCell>
                      <TableCell className="hidden text-white/50 xl:table-cell">{user.lastActive}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
              <div className="flex flex-col gap-3 border-t border-white/8 p-4 sm:flex-row sm:items-center">
                <AdminSelect id="user-action" name="action" defaultValue="pause">
                  <option value="pause">Pause selected</option>
                  <option value="restore">Restore selected</option>
                  <option value="approve deletion">Approve deletion</option>
                </AdminSelect>
                <button
                  type="submit"
                  className={cn(buttonVariants({ variant: "outline", size: "lg" }), "h-11 border-white/12 px-4")}
                >
                  Apply action
                </button>
                <p className="text-[11px] text-white/34 sm:ml-auto">
                  {filteredUsers.length} fictional records shown
                </p>
              </div>
            </>
          ) : (
            <div className="px-5 py-16 text-center">
              <p className="font-medium">No users match these filters</p>
              <p className="mx-auto mt-2 max-w-sm text-sm text-white/42">
                Try another user ID, masked email, or account status.
              </p>
              <Link
                href="/admin/users"
                className={cn(buttonVariants({ variant: "outline" }), "mt-5 h-11 border-white/12")}
              >
                Reset filters
              </Link>
            </div>
          )}
        </form>
      </section>

      <p className="max-w-3xl text-[11px] leading-5 text-white/34">
        The production workflow must require a second confirmation before account deletion and must remove associated personal data according to the final retention policy.
      </p>
    </div>
  );
}
