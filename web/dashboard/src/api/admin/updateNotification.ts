import { Notification } from '@dashboard/types/Admin';
import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/UpdateNotification';

export async function updateNotification(
  input: Notification & { adminId: UUID },
): Promise<Result<true, ApiError>> {
  const result = await mutate<T.UpdateNotification, T.UpdateNotificationVariables>(
    MUTATION,
    { input },
  );
  return result.mapApi(() => true);
}

const MUTATION = gql`
  mutation UpdateNotification($input: UpdateAdminNotificationInput!) {
    updateAdminNotification(input: $input) {
      id
    }
  }
`;
