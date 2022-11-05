import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/JoinWaitlist';

export async function joinWaitlist(email: string): Promise<Result<boolean, ApiError>> {
  const result = await mutate<T.JoinWaitlist, T.JoinWaitlistVariables>(MUTATION, {
    input: { email },
  });
  return result.mapApi(() => true);
}

// mutation

const MUTATION = gql`
  mutation JoinWaitlist($input: CreateWaitlistedUserInput!) {
    user: createWaitlistedUser(input: $input) {
      id
    }
  }
`;
