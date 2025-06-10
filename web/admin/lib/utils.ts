import type { AdminData } from './types';

export type AdminStatus =
  | `nada`
  | `onboardedButInactive`
  | `justMonitoring`
  | `justKeychains`
  | `superUser`;

export function getStatus(admin: AdminData): AdminStatus {
  const hasChildrenWithInstallation = admin.children.some(
    (child) => child.installations.length > 0,
  );
  const hasChildrenWithMonitoring = admin.children.some(
    (child) => child.keyloggingEnabled || child.screenshotsEnabled,
  );
  const hasKeychainsInUse =
    admin.numKeychains > 0 && admin.children.some((c) => c.numKeys > 0);
  const isAbleToUseTheApp = admin.subscriptionStatus !== `unpaid`;

  if (!hasChildrenWithInstallation) {
    return `nada`;
  }
  if (!isAbleToUseTheApp) {
    return `onboardedButInactive`;
  }
  if (hasChildrenWithMonitoring && hasKeychainsInUse) {
    return `superUser`;
  }
  if (hasChildrenWithMonitoring) {
    return `justMonitoring`;
  }
  if (hasKeychainsInUse) {
    return `justKeychains`;
  }
  return `onboardedButInactive`;
}

export function isActive(admin: AdminData): boolean {
  return getStatus(admin) !== `nada` && getStatus(admin) !== `onboardedButInactive`;
}

export function isOnboarded(admin: AdminData): boolean {
  return getStatus(admin) !== `nada`;
}
