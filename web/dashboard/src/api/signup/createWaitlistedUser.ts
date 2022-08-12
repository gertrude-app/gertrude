import Result from '../Result';
import * as T from './__generated__/CreateWaitlistedUser';
import { gql, mutate } from '../apollo';

export async function createWaitlistedUser(
  email: string,
): Promise<Result<boolean, never>> {
  const mutation = await mutate<T.CreateWaitlistedUser, T.CreateWaitlistedUserVariables>(
    MUTATION,
    { input: { email } },
  );

  return Result.success(mutation.isSuccess);
}

// mutation

const MUTATION = gql`
  mutation CreateWaitlistedUser($input: CreateWaitlistedUserInput!) {
    user: createWaitlistedUser(input: $input) {
      id
    }
  }
`;
