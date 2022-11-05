import type { UpdateSuspendFilterRequestInput } from '@dash/types';
import type Result from '../Result';
import type * as T from './__generated__/UpdateSuspendFilterRequest';
import { gql, mutate } from '../apollo';

export async function updateSuspendFilterRequest(
  input: UpdateSuspendFilterRequestInput,
): Promise<Result<true, ApiError>> {
  const result = await mutate<
    T.UpdateSuspendFilterRequest,
    T.UpdateSuspendFilterRequestVariables
  >(MUTATION, { input });
  return result.mapApi(() => true);
}

export const MUTATION = gql`
  mutation UpdateSuspendFilterRequest($input: UpdateSuspendFilterRequestInput!) {
    request: updateSuspendFilterRequest(input: $input) {
      id
    }
  }
`;
