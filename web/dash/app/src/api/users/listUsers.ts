import Result from '../Result';
import { gql, query } from '../apollo';
import * as T from './__generated__/ListUsers';
import { User } from './types';
import { mapKeychain } from '../keychains/listAdminKeychains';

export async function list(): Promise<Result<User[], ApiError>> {
  const result = await query<T.ListUsers>(QUERY);

  return result.mapApi((data) =>
    data.user.map((user) => ({
      ...user,
      keychains: user.keychains.map(mapKeychain),
    })),
  );
}

export const USER_FIELDS = gql`
  fragment UserFields on User {
    id
    name
    screenshotsEnabled
    screenshotsResolution
    screenshotsFrequency
    keyloggingEnabled
    keychains {
      id
      name
      description
      isPublic
      authorId
      keyRecords: keys {
        id
      }
    }
    devices {
      id
      isOnline
      model {
        family
        title: shortDescription
      }
    }
  }
`;

const QUERY = gql`
  ${USER_FIELDS}
  query ListUsers {
    user: getAdminUsers {
      ...UserFields
    }
  }
`;
