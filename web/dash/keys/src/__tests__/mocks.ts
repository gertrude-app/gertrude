import type { AppScope, Key } from '@dash/types';
import type * as EditKey from '../edit';
import { newKeyState } from '..';

export function key(overrides: Partial<Key> = {}): Key {
  return {
    id: `key-id`,
    keychainId: `keychain-id`,
    key: {
      type: `domain`,
      domain: `example.com`,
      scope: { type: `webBrowsers` },
    },
    ...overrides,
  };
}

export function domainKey(
  domain = `example.com`,
  scope: AppScope = { type: `webBrowsers` },
): Key {
  return {
    id: `key-id`,
    keychainId: `keychain-id`,
    key: {
      type: `domain`,
      domain,
      scope,
    },
  };
}

export function ipKey(
  ipAddress = `192.168.0.1`,
  scope: AppScope = { type: `webBrowsers` },
): Key {
  return {
    id: `key-id`,
    keychainId: `keychain-id`,
    key: {
      type: `ipAddress`,
      ipAddress,
      scope,
    },
  };
}

export function anySubdomainKey(
  domain = `example.com`,
  scope: AppScope = { type: `webBrowsers` },
): Key {
  return {
    id: `key-id`,
    keychainId: `keychain-id`,
    key: {
      type: `anySubdomain`,
      domain,
      scope,
    },
  };
}

export function keyState(overrides: Partial<EditKey.State> = {}): EditKey.State {
  return {
    ...newKeyState(`key-id`, `keychain-id`),
    keyType: `website`,
    ...overrides,
  };
}
