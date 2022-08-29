import Result from '../Result';
import { gql, query } from '../apollo';
import * as T from './__generated__/GetUser';

export async function getUser(id: UUID): Promise<Result<T.GetUser_user, ApiError>> {
  return (await query<T.GetUser, T.GetUserVariables>(QUERY, { id })).mapApi(
    (data) => data.user,
  );
}

const QUERY = gql`
  query GetUser($id: UUID!) {
    user: getUser(id: $id) {
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
  }
`;
