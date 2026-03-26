import type { Child, KeychainSummary, UnlockRequest } from '@dash/types';

export function keychain(id: UUID, adminId: UUID): KeychainSummary {
  return {
    id,
    name: ``,
    description: ``,
    isPublic: false,
    parentId: adminId,
    numKeys: 0,
  };
}

export function child(id: UUID): Child {
  return {
    id,
    name: ``,
    keyloggingEnabled: false,
    screenshotsEnabled: false,
    screenshotsResolution: 1000,
    screenshotsFrequency: 120,
    showSuspensionActivity: false,
    filteringDisabled: false,
    keychains: [],
    computers: [],
    iosDevices: [],
    createdAt: new Date().toISOString(),
  };
}

export function unlockRequest(id: UUID, userId: UUID): UnlockRequest {
  return {
    id,
    userId,
    userName: ``,
    status: `pending`,
    appCategories: [],
    createdAt: new Date().toISOString(),
  };
}
