import type Result from '../Result';
import type * as T from './__generated__/DeleteNotification';
import { gql, mutate } from '../apollo';

export async function deleteNotification(id: UUID): Promise<Result<true, ApiError>> {
  const result = await mutate<T.DeleteNotification, T.DeleteNotificationVariables>(
    MUTATION,
    { id },
  );
  return result.mapApi(() => true);
}

const MUTATION = gql`
  mutation DeleteNotification($id: UUID!) {
    deleteAdminNotification(id: $id) {
      id
    }
  }
`;
