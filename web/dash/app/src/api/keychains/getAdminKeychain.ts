import type { Keychain, KeyRecord, Key } from '@dash/keys';
import type Result from '../Result';
import type * as T from './__generated__/GetKeychain';
import { gql, query } from '../apollo';
import { KEYCHAIN_FIELDS, mapKeychain } from './listAdminKeychains';

export async function getAdminKeychain(
  id: UUID,
): Promise<Result<[Keychain, KeyRecord[]], ApiError>> {
  const result = await query<T.GetKeychain, T.GetKeychainVariables>(QUERY, {
    id,
  });
  return result.mapApi((data) => [
    mapKeychain(data.keychain),
    data.keychain.keyRecords.map((keyRecord) => ({
      id: keyRecord.id,
      keychainId: data.keychain.id,
      comment: keyRecord.comment,
      expiration: keyRecord.expiration,
      key: keyRecord.key.data as Key,
    })),
  ]);
}

const QUERY = gql`
  ${KEYCHAIN_FIELDS}
  query GetKeychain($id: UUID!) {
    keychain: getKeychain(id: $id) {
      ...KeychainFields
    }
  }
`;
