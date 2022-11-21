import { RequestStatus } from '@dash/types';
import type { UnlockRequest } from '@dash/types';
import type { Keychain } from '@dash/keys';
import type { User } from '../api/users';

export function keychain(id: UUID, adminId: UUID): Keychain {
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
    keychains: [],
    devices: [],
  };
}

export function unlockRequest(id: UUID, userId: UUID): UnlockRequest {
  return {
    id,
    userId,
    userName: ``,
    status: RequestStatus.pending,
    appCategories: [],
    createdAt: new Date().toISOString(),
  };
}
