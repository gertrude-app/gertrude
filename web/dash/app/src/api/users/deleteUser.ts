import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/DeleteUser';

export async function deleteUser(id: UUID): Promise<Result<true, ApiError>> {
  const result = await mutate<T.DeleteUser, T.DeleteUserVariables>(MUTATION, { id });
  return result.mapApi(() => true);
}

const MUTATION = gql`
  mutation DeleteUser($id: UUID!) {
    device: deleteUser(id: $id) {
      id
    }
  }
`;
