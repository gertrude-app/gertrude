import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/SetUserKeychains';

export async function setUserKeychains(
  userId: UUID,
  keychainIds: UUID[],
): Promise<Result<true, ApiError>> {
  const result = await mutate<T.SetUserKeychains, T.SetUserKeychainsVariables>(MUTATION, {
    input: { userId, keychainIds },
  });
  return result.mapApi(() => true);
}

const MUTATION = gql`
  mutation SetUserKeychains($input: SetUserKeychainsInput!) {
    user: setUserKeychains(input: $input) {
      id
    }
  }
`;
