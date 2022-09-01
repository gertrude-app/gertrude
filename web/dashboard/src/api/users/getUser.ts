import Result from '../Result';
import { gql, query } from '../apollo';
import * as T from './__generated__/GetUser';
import { USER_FIELDS } from './listUsers';
import { User } from './types';

export async function getUser(id: UUID): Promise<Result<User, ApiError>> {
  return (await query<T.GetUser, T.GetUserVariables>(QUERY, { id })).mapApi(
    (data) => data.user,
  );
}

const QUERY = gql`
  ${USER_FIELDS}
  query GetUser($id: UUID!) {
    user: getUser(id: $id) {
      ...UserFields
    }
  }
`;
