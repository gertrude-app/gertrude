import Result from '../Result';
import { gql, query } from '../apollo';
import { mapKeychain } from '../keychains/listAdminKeychains';
import * as T from './__generated__/GetUser';
import { USER_FIELDS } from './listUsers';
import { User } from './types';

export async function getUser(id: UUID): Promise<Result<User, ApiError>> {
  const result = await query<T.GetUser, T.GetUserVariables>(QUERY, { id });
  return result.mapApi((data) => ({
    ...data.user,
    keychains: data.user.keychains.map(mapKeychain),
  }));
}

const QUERY = gql`
  ${USER_FIELDS}
  query GetUser($id: UUID!) {
    user: getUser(id: $id) {
      ...UserFields
    }
  }
`;
