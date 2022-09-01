import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/DeleteKeychain';

export async function deleteKeychain(id: UUID): Promise<Result<true, ApiError>> {
  const result = await mutate<T.DeleteKeychain, T.DeleteKeychainVariables>(MUTATION, {
    id,
  });
  return result.mapApi(() => true);
}

const MUTATION = gql`
  mutation DeleteKeychain($id: UUID!) {
    keychain: deleteKeychain(id: $id) {
      id
    }
  }
`;
