import { Keychain } from '@dash/keys';
import type { ListUsers_user } from './__generated__/ListUsers';

export type User = Omit<ListUsers_user, '__typename' | 'keychains'> & {
  keychains: Keychain[];
};
