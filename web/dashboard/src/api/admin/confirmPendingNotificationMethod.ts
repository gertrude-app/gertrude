import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/ConfirmPendingNotificationMethod';

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
