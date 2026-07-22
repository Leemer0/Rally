import { authenticated, ApiError } from "../_shared/http.ts";
import { callRpc } from "../_shared/rpc.ts";

function optionalPeriodDate(url: URL, name: string): string | null {
  const value = url.searchParams.get(name);
  if (value === null) return null;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw new ApiError(
      "INVALID_REQUEST",
      `${name} must be a YYYY-MM-DD date.`,
      400,
      { field: name },
    );
  }
  const date = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(date.valueOf()) || date.toISOString().slice(0, 10) !== value) {
    throw new ApiError(
      "INVALID_REQUEST",
      `${name} must be a valid calendar date.`,
      400,
      { field: name },
    );
  }
  return value;
}

export default {
  fetch: authenticated(["GET"], async (request, context) => {
    const url = new URL(request.url);
    const unexpected = [...url.searchParams.keys()].filter((key) =>
      key !== "period_start" && key !== "period_end"
    );
    if (unexpected.length) {
      throw new ApiError(
        "INVALID_REQUEST",
        "The request contains unsupported query parameters.",
        400,
        { fields: unexpected.sort() },
      );
    }

    const dashboard = await callRpc<Record<string, unknown>>(
      context.supabaseAdmin,
      "get_venue_dashboard_snapshot",
      {
        p_user_id: context.userId,
        p_period_start: optionalPeriodDate(url, "period_start"),
        p_period_end: optionalPeriodDate(url, "period_end"),
      },
      context.requestId,
    );

    return context.respond(dashboard);
  }),
};
