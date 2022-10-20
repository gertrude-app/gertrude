import { UpdateSuspendFilterRequestInput } from '@dashboard/types/GraphQL';
import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/UpdateSuspendFilterRequest';

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
