import Result from '../Result';
import * as T from './__generated__/JoinWaitlist';
import { gql, mutate } from '../apollo';

export async function joinWaitlist(email: string): Promise<Result<boolean, never>> {
  const mutation = await mutate<T.JoinWaitlist, T.JoinWaitlistVariables>(MUTATION, {
    input: { email },
  });
  return Result.success(mutation.isSuccess);
}

// mutation

const MUTATION = gql`
  mutation JoinWaitlist($input: CreateWaitlistedUserInput!) {
    user: createWaitlistedUser(input: $input) {
      id
    }
  }
`;
