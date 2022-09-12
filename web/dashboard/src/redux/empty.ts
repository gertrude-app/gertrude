import { unsavedId } from '@shared/lib/id';
import { User } from '../api/users';

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
