import type Result from '../Result';
import type * as T from './__generated__/CreateBillingPortalSession';
import { gql, mutate } from '../apollo';

export async function createBillingPortalSession(
  adminId: UUID,
): Promise<Result<string, ApiError>> {
  const result = await mutate<
    T.CreateBillingPortalSession,
    T.CreateBillingPortalSessionVariables
  >(MUTATION, {
    input: { uuid: adminId },
  });
  return result.mapApi((data) => data.session.url);
}

const MUTATION = gql`
  mutation CreateBillingPortalSession($input: UUIDInput!) {
    session: createBillingPortalSession(input: $input) {
      url
    }
  }
`;
