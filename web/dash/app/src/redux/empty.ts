import { unsavedId } from '@dash/utils';
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

export function user(): User {
  return {
    id: unsavedId(),
    name: ``,
    keyloggingEnabled: false,
    screenshotsEnabled: false,
    screenshotsResolution: 1000,
    screenshotsFrequency: 120,
    keychains: [],
    devices: [],
  };
}
