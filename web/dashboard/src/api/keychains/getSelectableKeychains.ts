import Result from '../Result';
import * as T from './__generated__/GetSelectableKeychains';
import { gql, query } from '../apollo';
import { mapKeychain } from './listAdminKeychains';

export async function getSelectableKeychains(): Promise<
  Result<{ own: Keychain[]; public: Keychain[] }, ApiError>
> {
  const result = await query<T.GetSelectableKeychains>(QUERY);
  return result.mapApi((data) => ({
    own: data.own.map(mapKeychain),
    public: data.public.map(mapKeychain),
  }));
}

export const QUERY = gql`
  query GetSelectableKeychains {
    own: getAdminKeychains {
      id
      name
      isPublic
      authorId
      description
      keyRecords: keys {
        id
      }
    }
    public: getPublicKeychains {
      id
      name
      isPublic
      authorId
      description
      keyRecords: keys {
        id
      }
    }
  }
`;
