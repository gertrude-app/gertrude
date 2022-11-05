import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/DeleteNotificationMethod';

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
