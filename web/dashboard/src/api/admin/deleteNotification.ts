import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/DeleteNotification';

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
