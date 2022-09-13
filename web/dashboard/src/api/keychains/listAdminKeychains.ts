import Result from '../Result';
import * as T from './__generated__/ListAdminKeychains';
import { gql, query } from '../apollo';

export async function listAdminKeychains(): Promise<
  Result<T.ListAdminKeychains['keychains'], ApiError>
> {
  const result = await query<T.ListAdminKeychains>(QUERY);
  return result.mapApi((data) => data.keychains);
}

export const KEYCHAIN_FIELDS = gql`
  fragment KeychainFields on Keychain {
    id
    name
    description
    isPublic
    authorId
    keys {
      id
    }
  }
`;

// mutation

const QUERY = gql`
  ${KEYCHAIN_FIELDS}
  query ListAdminKeychains {
    keychains: getAdminKeychains {
      ...KeychainFields
    }
  }
`;
