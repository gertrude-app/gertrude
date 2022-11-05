import type Result from '../Result';
import type * as T from './__generated__/DeleteNotificationMethod';
import { gql, mutate } from '../apollo';

export async function deleteNotificationMethod(
  id: UUID,
): Promise<Result<true, ApiError>> {
  const result = await mutate<
    T.DeleteNotificationMethod,
    T.DeleteNotificationMethodVariables
  >(MUTATION, { id });
  return result.mapApi(() => true);
}

const MUTATION = gql`
  mutation DeleteNotificationMethod($id: UUID!) {
    deleteAdminVerifiedNotificationMethod(id: $id) {
      id
    }
  }
`;
