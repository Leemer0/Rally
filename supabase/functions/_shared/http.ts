import {
  createSupabaseContext,
  type SupabaseContext,
} from "@supabase/server";
import { createClient } from "@supabase/supabase-js";

const DEFAULT_ALLOWED_ORIGINS = [
  "https://getoutly.app",
  "https://www.getoutly.app",
  "http://localhost:3000",
  "http://127.0.0.1:3000",
];

export type JsonObject = Record<string, unknown>;

export class ApiError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly status: number,
    readonly details?: unknown,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

export interface AuthenticatedRequestContext {
  supabase: SupabaseContext["supabase"];
  supabaseAdmin: SupabaseContext["supabaseAdmin"];
  userId: string;
  requestId: string;
  respond: (data: unknown, status?: number) => Response;
}

type AuthenticatedHandler = (
  request: Request,
  context: AuthenticatedRequestContext,
) => Promise<Response>;

interface LegacyAuthContext {
  supabase: SupabaseContext["supabase"];
  supabaseAdmin: SupabaseContext["supabaseAdmin"];
  userId: string;
}

function namedKey(environmentName: string): string | null {
  const raw = Deno.env.get(environmentName);
  if (!raw) return null;
  try {
    const keys = JSON.parse(raw) as Record<string, unknown>;
    if (typeof keys.default === "string") return keys.default;
    const first = Object.values(keys).find((value) => typeof value === "string");
    return typeof first === "string" ? first : null;
  } catch {
    return null;
  }
}

function bearerToken(request: Request): string | null {
  const authorization = request.headers.get("authorization") ?? "";
  const match = /^Bearer ([^\s]+)$/i.exec(authorization);
  return match?.[1] ?? null;
}

async function legacyJwtContext(
  request: Request,
): Promise<LegacyAuthContext | null> {
  const token = bearerToken(request);
  const url = Deno.env.get("SUPABASE_URL");
  const publishableKey = Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ??
    Deno.env.get("SUPABASE_ANON_KEY") ??
    namedKey("SUPABASE_PUBLISHABLE_KEYS");
  const secretKey = Deno.env.get("SUPABASE_SECRET_KEY") ??
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    namedKey("SUPABASE_SECRET_KEYS");

  if (!token || !url || !publishableKey || !secretKey) return null;

  const authOptions = {
    persistSession: false,
    autoRefreshToken: false,
    detectSessionInUrl: false,
  };
  const verifier = createClient(url, publishableKey, { auth: authOptions });
  const { data, error } = await verifier.auth.getUser(token);
  if (error || !data.user?.id) return null;

  return {
    supabase: createClient(url, publishableKey, {
      auth: authOptions,
      global: { headers: { Authorization: `Bearer ${token}` } },
    }),
    supabaseAdmin: createClient(url, secretKey, { auth: authOptions }),
    userId: data.user.id,
  };
}

function configuredOrigins(): Set<string> {
  const configured = Deno.env.get("OUTLY_ALLOWED_ORIGINS")
    ?.split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);

  return new Set(configured?.length ? configured : DEFAULT_ALLOWED_ORIGINS);
}

function requestIdFor(request: Request): string {
  const supplied = request.headers.get("x-request-id");
  return supplied && /^[A-Za-z0-9._-]{1,100}$/.test(supplied)
    ? supplied
    : crypto.randomUUID();
}

function corsHeaders(request: Request): Headers {
  const headers = new Headers({
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type, x-request-id",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Max-Age": "86400",
    "Vary": "Origin",
  });
  const origin = request.headers.get("origin");

  if (!origin) return headers;
  if (!configuredOrigins().has(origin)) {
    throw new ApiError(
      "ORIGIN_NOT_ALLOWED",
      "This web origin is not allowed to call the Outly API.",
      403,
    );
  }

  headers.set("Access-Control-Allow-Origin", origin);
  return headers;
}

function jsonResponse(
  body: unknown,
  status: number,
  headers: Headers,
  requestId: string,
): Response {
  const responseHeaders = new Headers(headers);
  responseHeaders.set("Content-Type", "application/json; charset=utf-8");
  responseHeaders.set("Cache-Control", "no-store");
  responseHeaders.set("x-request-id", requestId);
  return new Response(JSON.stringify(body), { status, headers: responseHeaders });
}

function errorResponse(
  error: ApiError,
  headers: Headers,
  requestId: string,
): Response {
  return jsonResponse(
    {
      error: {
        code: error.code,
        message: error.message,
        ...(error.details === undefined ? {} : { details: error.details }),
      },
      request_id: requestId,
    },
    error.status,
    headers,
    requestId,
  );
}

export function authenticated(
  methods: readonly ("GET" | "POST")[],
  handler: AuthenticatedHandler,
): (request: Request) => Promise<Response> {
  return async (request: Request): Promise<Response> => {
    const requestId = requestIdFor(request);
    let headers = new Headers();

    try {
      headers = corsHeaders(request);

      if (request.method === "OPTIONS") {
        return new Response(null, { status: 204, headers });
      }
      if (!methods.includes(request.method as "GET" | "POST")) {
        const methodError = new ApiError(
          "METHOD_NOT_ALLOWED",
          `Use ${methods.join(" or ")} for this endpoint.`,
          405,
        );
        const response = errorResponse(methodError, headers, requestId);
        response.headers.set("Allow", [...methods, "OPTIONS"].join(", "));
        return response;
      }

      const { data: authContext, error: authError } =
        await createSupabaseContext(request, { auth: "user" });

      const legacyContext = authError || !authContext?.userClaims?.id
        ? await legacyJwtContext(request)
        : null;

      if ((!authContext?.userClaims?.id || authError) && !legacyContext) {
        const authFailure = authError as {
          code?: string;
          status?: number;
        } | null;
        console.warn(JSON.stringify({
          request_id: requestId,
          operation: "authenticate_request",
          auth_error_code: authFailure?.code ?? "missing_user_claims",
          auth_error_status: authFailure?.status ?? 401,
        }));
        throw new ApiError(
          "UNAUTHORIZED",
          "A valid signed-in Supabase session is required.",
          401,
        );
      }

      const respond = (data: unknown, status = 200) =>
        jsonResponse({ data }, status, headers, requestId);

      return await handler(request, {
        supabase: legacyContext?.supabase ?? authContext!.supabase,
        supabaseAdmin: legacyContext?.supabaseAdmin ?? authContext!.supabaseAdmin,
        userId: legacyContext?.userId ?? authContext!.userClaims!.id,
        requestId,
        respond,
      });
    } catch (error) {
      if (error instanceof ApiError) {
        return errorResponse(error, headers, requestId);
      }

      console.error(JSON.stringify({
        request_id: requestId,
        code: "UNHANDLED_EDGE_FUNCTION_ERROR",
        error_name: error instanceof Error ? error.name : "UnknownError",
      }));
      return errorResponse(
        new ApiError(
          "INTERNAL_ERROR",
          "The request could not be completed.",
          500,
        ),
        headers,
        requestId,
      );
    }
  };
}

export async function readJsonObject(
  request: Request,
  maximumBytes = 32_768,
): Promise<JsonObject> {
  const contentType = request.headers.get("content-type")?.toLowerCase() ?? "";
  if (!contentType.includes("application/json")) {
    throw new ApiError(
      "UNSUPPORTED_MEDIA_TYPE",
      "Send the request body as application/json.",
      415,
    );
  }

  const declaredLength = Number(request.headers.get("content-length") ?? "0");
  if (Number.isFinite(declaredLength) && declaredLength > maximumBytes) {
    throw new ApiError(
      "REQUEST_TOO_LARGE",
      "The request body is too large.",
      413,
    );
  }

  const text = await request.text();
  if (new TextEncoder().encode(text).byteLength > maximumBytes) {
    throw new ApiError(
      "REQUEST_TOO_LARGE",
      "The request body is too large.",
      413,
    );
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    throw new ApiError(
      "INVALID_JSON",
      "The request body is not valid JSON.",
      400,
    );
  }

  if (!isJsonObject(parsed)) {
    throw new ApiError(
      "INVALID_REQUEST",
      "The request body must be a JSON object.",
      400,
    );
  }

  return parsed;
}

export function isJsonObject(value: unknown): value is JsonObject {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
