import { DecideUnlockRequestInput } from '@dash/types';
import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/DecideUnlockRequest';

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
