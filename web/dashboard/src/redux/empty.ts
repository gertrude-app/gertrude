import { unsavedId } from '@dashboard/lib/id';
import { User } from '../api/users';

export function keychain(id: UUID, adminId: UUID): Keychain {
  return {
    id,
    name: ``,
    description: ``,
    isPublic: false,
    authorId: adminId,
    keyRecords: {},
  };
}

export function user(): User {
  return {
    id: unsavedId(),
    __typename: `User`,
    name: ``,
    keyloggingEnabled: false,
    screenshotsEnabled: false,
    screenshotsResolution: 1000,
    screenshotsFrequency: 120,
    keychains: [],
    devices: [],
  };
}
