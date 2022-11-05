import type { DecideUnlockRequestInput } from '@dash/types';
import type Result from '../Result';
import type * as T from './__generated__/DecideUnlockRequest';
import { gql, mutate } from '../apollo';

export async function updateUnlockRequest(
  input: DecideUnlockRequestInput,
): Promise<Result<true, ApiError>> {
  const result = await mutate<T.DecideUnlockRequest, T.DecideUnlockRequestVariables>(
    MUTATION,
    { input },
  );
  return result.mapApi(() => true);
}

const MUTATION = gql`
  mutation DecideUnlockRequest($input: DecideUnlockRequestInput!) {
    unlockRequest: decideUnlockRequest(input: $input) {
      id
    }
  }
`;
