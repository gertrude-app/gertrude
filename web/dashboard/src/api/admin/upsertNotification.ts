import { UpdateAdminNotificationInput } from '@dashboard/types/GraphQL';
import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as U from './__generated__/UpdateNotification';
import * as C from './__generated__/CreateNotification';
import { isUnsaved } from '@dashboard/lib/id';

export async function upsertNotification(
  input: UpdateAdminNotificationInput,
): Promise<Result<UUID, ApiError>> {
  if (isUnsaved(input.id)) {
    const result = await mutate<C.CreateNotification, C.CreateNotificationVariables>(
      CREATE_MUTATION,
      { input: { ...input, id: undefined } },
    );
    return result.mapApi((data) => data.notification.id);
  }

  const result = await mutate<U.UpdateNotification, U.UpdateNotificationVariables>(
    UPDATE_MUTATION,
    { input },
  );
  return result.mapApi((data) => data.notification.id);
}

const CREATE_MUTATION = gql`
  mutation CreateNotification($input: CreateAdminNotificationInput!) {
    notification: createAdminNotification(input: $input) {
      id
    }
  }
`;

const UPDATE_MUTATION = gql`
  mutation UpdateNotification($input: UpdateAdminNotificationInput!) {
    notification: updateAdminNotification(input: $input) {
      id
    }
  }
`;
