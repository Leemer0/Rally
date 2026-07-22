export function safeNextPath(value: FormDataEntryValue | string | null | undefined) {
  if (typeof value !== "string") {
    return null;
  }

  const path = value.trim();

  if (!path.startsWith("/") || path.startsWith("//") || path.includes("\\")) {
    return null;
  }

  return path;
}
