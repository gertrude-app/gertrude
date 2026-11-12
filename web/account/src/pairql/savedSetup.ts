import type { GetAccountSetup } from '@shared/pairql/src/account';

const SAVED_SETUP_KEY = `account_setup`;

export function readSavedSetup(
  accountId: string | null,
): GetAccountSetup.Output | undefined {
  if (!accountId) return undefined;
  try {
    const saved: unknown = JSON.parse(localStorage.getItem(SAVED_SETUP_KEY) ?? `null`);
    if (!isSavedSetup(saved) || saved.accountId !== accountId) return undefined;
    return saved.setup;
  } catch {
    return undefined;
  }
}

export function saveSetup(accountId: string | null, setup: GetAccountSetup.Output): void {
  if (!accountId) return;
  localStorage.setItem(SAVED_SETUP_KEY, JSON.stringify({ accountId, setup }));
}

export function clearSavedSetup(): void {
  localStorage.removeItem(SAVED_SETUP_KEY);
}

function isSavedSetup(
  value: unknown,
): value is { accountId: string; setup: GetAccountSetup.Output } {
  if (typeof value !== `object` || value === null) return false;
  const { accountId, setup } = value as Record<string, unknown>;
  if (typeof accountId !== `string` || typeof setup !== `object` || setup === null) {
    return false;
  }
  const { selectedApps, hasPeople, completedApps, hasNotifications } = setup as Record<
    string,
    unknown
  >;
  return (
    (selectedApps === undefined || Array.isArray(selectedApps)) &&
    typeof hasPeople === `boolean` &&
    Array.isArray(completedApps) &&
    typeof hasNotifications === `boolean`
  );
}
