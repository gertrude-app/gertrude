export function normalizedBundleId(bundleId: string): string {
  const stripped = bundleId.startsWith(`.`) ? bundleId.slice(1) : bundleId;
  const parts = stripped.split(`.`);
  const first = parts[0] ?? ``;
  if (parts.length > 1 && /^[A-Z0-9]{10}$/.test(first)) {
    return parts.slice(1).join(`.`);
  }
  return stripped;
}

export function toSlug(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, `-`)
    .replace(/^-|-$/g, ``);
}
