import { expect, test, describe, vi } from 'vitest';
import * as convert from '@dash/keys';
import { upsertEditingKey } from '../slice-keychains';
import Current from '../../environment';
import { makeGetState } from './test-helpers';
import * as mocks from './mocks';

describe(`reducer`, () => {
  test(`saving key sends expiration in server format`, () => {
    Current.api.saveKey = vi.fn();

    const editingKey = mocks.editKeyState({
      id: `key-id`,
      keychainId: `keychain-id`,
      isNew: false,
      expiration: new Date().toISOString(),
      comment: `some comment`,
    });

    const getState = makeGetState((state) => {
      state.keychains.editingKey = editingKey;
    });

    upsertEditingKey()(vi.fn(), getState);

    expect(Current.api.saveKey).toHaveBeenCalledWith({
      isNew: false,
      id: `key-id`,
      keychainId: `keychain-id`,
      key: convert.toKeyRecord(editingKey)!.key,
      comment: `some comment`,

      // fractional milliseconds removed for Swift Decodable decoding
      expiration: editingKey.expiration!.replace(/\.\d\d\dZ$/, `Z`),
    });
  });
});
