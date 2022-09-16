import { unsavedId } from '@shared/lib/id';
import { User } from '../api/users';
import { Keychain } from '../api/keychains';

export function keychain(id: UUID, adminId: UUID): Keychain {
  return {
    __typename: `Keychain`,
    id,
    name: ``,
    description: ``,
    isPublic: false,
    authorId: adminId,
    keys: [],
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
