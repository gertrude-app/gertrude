const SHORT_URL_PREFIX = `https://gertrude.app/u/`;
const REFERRAL_CODE_PATTERN = /^[2-9A-HJ-NP-Z]{7}$/;

export function normalizeReferralCode(
  value: string | null | undefined,
): string | undefined {
  const normalized = value?.trim().toUpperCase();
  return normalized || undefined;
}

export function friendShareUrl(value: string | null | undefined): string | undefined {
  const code = normalizeReferralCode(value);
  if (!code || !REFERRAL_CODE_PATTERN.test(code)) {
    return undefined;
  }
  return `${SHORT_URL_PREFIX}${code}`;
}

export async function copyToClipboard(text: string): Promise<boolean> {
  try {
    if (!globalThis.navigator?.clipboard?.writeText) {
      return false;
    }
    await globalThis.navigator.clipboard.writeText(text);
    return true;
  } catch {
    return false;
  }
}
