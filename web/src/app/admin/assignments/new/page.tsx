import { redirect } from "next/navigation";

export default function NewAssignmentPage() {
  redirect("/admin/partners/new?mode=offer");
}
