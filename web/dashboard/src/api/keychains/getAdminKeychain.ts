import Result from '../Result';
import { gql, query } from '../apollo';
import { KEYCHAIN_FIELDS, mapKeychain } from './listAdminKeychains';
import * as T from './__generated__/GetKeychain';

export async function getAdminKeychain(id: UUID): Promise<Result<Keychain, ApiError>> {
  const result = await query<T.GetKeychain, T.GetKeychainVariables>(Query, {
    id,
  });
  return result.mapApi((data) => mapKeychain(data.keychain));
}

const Query = gql`
  ${KEYCHAIN_FIELDS}
  query GetKeychain($id: UUID!) {
    keychain: getKeychain(id: $id) {
      ...KeychainFields
    }
  }
`;
