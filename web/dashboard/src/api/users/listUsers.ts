import Result from '../Result';
import { gql, query } from '../apollo';
import * as T from './__generated__/ListUsers';
import { User } from './types';

export async function list(): Promise<Result<User[], ApiError>> {
  return (await query<T.ListUsers>(QUERY)).mapApi((data) => data.user);
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
      keys {
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
