import type { KeychainSummary, UnlockRequest, User } from '@dash/types';

export function keychain(id: UUID, adminId: UUID): KeychainSummary {
  return {
    id,
    name: ``,
    description: ``,
    isPublic: false,
    authorId: adminId,
    numKeys: 0,
  };
}

export function user(id: UUID): User {
  return {
    id,
    name: ``,
    keyloggingEnabled: false,
    screenshotsEnabled: false,
    screenshotsResolution: 1000,
    screenshotsFrequency: 120,
    showSuspensionActivity: false,
    keychains: [],
    devices: [],
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
