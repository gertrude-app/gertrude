import type Result from '../Result';
import type * as T from './__generated__/ConfirmPendingNotificationMethod';
import { gql, mutate } from '../apollo';

export async function confirmPendingNotificationMethod(
  id: UUID,
  code: number,
): Promise<Result<boolean, ApiError>> {
  const result = await mutate<
    T.ConfirmPendingNotificationMethod,
    T.ConfirmPendingNotificationMethodVariables
  >(MUTATION, { id, code });
  return result.mapApi((data) => data.method.success);
}

const MUTATION = gql`
  mutation ConfirmPendingNotificationMethod($id: UUID!, $code: Int!) {
    method: confirmPendingAdminNotificationMethod(id: $id, code: $code) {
      success
    }
  }
`;
