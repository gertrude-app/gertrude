import Result from '../Result';
import { gql, query } from '../apollo';
import * as T from './__generated__/ListUsers';

export async function list(): Promise<Result<T.ListUsers_user[], ApiError>> {
  return (await query<T.ListUsers>(QUERY)).mapApi((data) => data.user);
}

const QUERY = gql`
  query ListUsers {
    user: getAdminUsers {
      id
      name
      screenshotsEnabled
      keystrokesEnabled: keyloggingEnabled
      keychains {
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
  }
`;
