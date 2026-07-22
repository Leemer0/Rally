import { ApiError, type JsonObject } from "./http.ts";

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
const TIME_PATTERN = /^(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d(?:\.\d{1,6})?)?$/;
const DATE_TIME_WITH_ZONE_PATTERN =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/i;
const PARTNER_MEDIA_PATH_PATTERN =
  /^partner-media\/[A-Za-z0-9][A-Za-z0-9._/-]*$/;

function invalid(field: string, message: string): never {
  throw new ApiError("INVALID_REQUEST", message, 400, { field });
}

export function assertOnlyKeys(
  object: JsonObject,
  allowedKeys: readonly string[],
): void {
  const allowed = new Set(allowedKeys);
  const unexpected = Object.keys(object).filter((key) => !allowed.has(key));
  if (unexpected.length) {
    throw new ApiError(
      "INVALID_REQUEST",
      "The request contains unsupported fields.",
      400,
      { fields: unexpected.sort() },
    );
  }
}

export function requiredString(
  object: JsonObject,
  field: string,
  minimumLength: number,
  maximumLength: number,
): string {
  const value = object[field];
  if (typeof value !== "string") {
    return invalid(field, `${field} must be a string.`);
  }
  const trimmed = value.trim();
  if (trimmed.length < minimumLength || trimmed.length > maximumLength) {
    return invalid(
      field,
      `${field} must contain ${minimumLength}-${maximumLength} characters.`,
    );
  }
  return trimmed;
}

export function optionalString(
  object: JsonObject,
  field: string,
  minimumLength: number,
  maximumLength: number,
): string | null {
  const value = object[field];
  if (value === undefined || value === null || value === "") return null;
  return requiredString(object, field, minimumLength, maximumLength);
}

export function requiredPartnerMediaPath(
  object: JsonObject,
  field: string,
): string {
  const value = requiredString(object, field, 15, 512);
  const segments = value.split("/");
  if (
    !PARTNER_MEDIA_PATH_PATTERN.test(value) ||
    segments.some((segment) => !segment || segment === "." || segment === "..")
  ) {
    return invalid(
      field,
      `${field} must be an approved partner-media storage path.`,
    );
  }
  return value;
}

export function requiredUuid(object: JsonObject, field: string): string {
  const value = object[field];
  if (typeof value !== "string" || !UUID_PATTERN.test(value)) {
    return invalid(field, `${field} must be a UUID.`);
  }
  return value.toLowerCase();
}

export function optionalUuid(
  object: JsonObject,
  field: string,
): string | null {
  const value = object[field];
  if (value === undefined || value === null) return null;
  return requiredUuid(object, field);
}

function validCalendarDate(value: string): boolean {
  if (!DATE_PATTERN.test(value)) return false;
  const instant = new Date(`${value}T00:00:00.000Z`);
  return !Number.isNaN(instant.valueOf()) &&
    instant.toISOString().slice(0, 10) === value;
}

export function requiredDate(object: JsonObject, field: string): string {
  const value = object[field];
  if (typeof value !== "string" || !validCalendarDate(value)) {
    return invalid(field, `${field} must be a valid YYYY-MM-DD date.`);
  }
  return value;
}

export function optionalDate(
  object: JsonObject,
  field: string,
): string | null {
  const value = object[field];
  if (value === undefined || value === null) return null;
  return requiredDate(object, field);
}

export function requiredDateTime(object: JsonObject, field: string): string {
  const value = object[field];
  if (
    typeof value !== "string" ||
    !DATE_TIME_WITH_ZONE_PATTERN.test(value) ||
    Number.isNaN(Date.parse(value))
  ) {
    return invalid(
      field,
      `${field} must be an ISO 8601 timestamp with a timezone.`,
    );
  }
  return new Date(value).toISOString();
}

export function optionalDateTime(
  object: JsonObject,
  field: string,
): string | null {
  const value = object[field];
  if (value === undefined || value === null) return null;
  return requiredDateTime(object, field);
}

export function optionalTime(
  object: JsonObject,
  field: string,
): string | null {
  const value = object[field];
  if (value === undefined || value === null) return null;
  if (typeof value !== "string" || !TIME_PATTERN.test(value)) {
    return invalid(field, `${field} must be a 24-hour local time.`);
  }
  return value;
}

export function requiredEnum<const T extends readonly string[]>(
  object: JsonObject,
  field: string,
  allowed: T,
): T[number] {
  const value = object[field];
  if (typeof value !== "string" || !allowed.includes(value)) {
    return invalid(field, `${field} must be one of: ${allowed.join(", ")}.`);
  }
  return value as T[number];
}

export function requiredBoolean(object: JsonObject, field: string): boolean {
  const value = object[field];
  if (typeof value !== "boolean") {
    return invalid(field, `${field} must be a boolean.`);
  }
  return value;
}

export function optionalBoolean(
  object: JsonObject,
  field: string,
  fallback: boolean,
): boolean {
  return object[field] === undefined
    ? fallback
    : requiredBoolean(object, field);
}

export function requiredNumber(
  object: JsonObject,
  field: string,
  minimum: number,
  maximum: number,
): number {
  const value = object[field];
  if (
    typeof value !== "number" ||
    !Number.isFinite(value) ||
    value < minimum ||
    value > maximum
  ) {
    return invalid(field, `${field} must be between ${minimum} and ${maximum}.`);
  }
  return value;
}

export function optionalNumber(
  object: JsonObject,
  field: string,
  minimum: number,
  maximum: number,
): number | null {
  const value = object[field];
  if (value === undefined || value === null) return null;
  return requiredNumber(object, field, minimum, maximum);
}

export function optionalInteger(
  object: JsonObject,
  field: string,
  minimum: number,
  maximum: number,
): number | null {
  const value = object[field];
  if (value === undefined || value === null) return null;
  if (
    typeof value !== "number" ||
    !Number.isSafeInteger(value) ||
    value < minimum ||
    value > maximum
  ) {
    return invalid(
      field,
      `${field} must be an integer between ${minimum} and ${maximum}.`,
    );
  }
  return value;
}

export function requiredIntegerArray(
  object: JsonObject,
  field: string,
  minimum: number,
  maximum: number,
): number[] {
  const value = object[field];
  if (
    !Array.isArray(value) ||
    value.length === 0 ||
    value.some((entry) =>
      typeof entry !== "number" ||
      !Number.isInteger(entry) ||
      entry < minimum ||
      entry > maximum
    )
  ) {
    return invalid(
      field,
      `${field} must be a non-empty array of integers between ${minimum} and ${maximum}.`,
    );
  }
  return [...new Set(value as number[])].sort((left, right) => left - right);
}

export function requiredUuidArray(
  object: JsonObject,
  field: string,
  maximumCount = 100,
): string[] {
  const value = object[field];
  if (!Array.isArray(value) || value.length === 0 || value.length > maximumCount) {
    return invalid(
      field,
      `${field} must contain 1-${maximumCount} venue UUIDs.`,
    );
  }
  const normalized = value.map((entry) => {
    if (typeof entry !== "string" || !UUID_PATTERN.test(entry)) {
      return invalid(field, `${field} must contain only UUIDs.`);
    }
    return entry.toLowerCase();
  });
  return [...new Set(normalized)];
}

export function requiredEmail(object: JsonObject, field: string): string {
  const email = requiredString(object, field, 3, 254).toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return invalid(field, `${field} must be a valid email address.`);
  }
  return email;
}

export function requiredHttpsUrl(object: JsonObject, field: string): string {
  const value = requiredString(object, field, 8, 2048);
  try {
    const url = new URL(value);
    if (url.protocol !== "https:" || !url.hostname) throw new Error();
    return url.toString();
  } catch {
    return invalid(field, `${field} must be a valid HTTPS URL.`);
  }
}

export function optionalHttpsUrl(
  object: JsonObject,
  field: string,
): string | null {
  const value = object[field];
  if (value === undefined || value === null || value === "") return null;
  return requiredHttpsUrl(object, field);
}
