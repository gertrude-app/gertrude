import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/UpdateUser';
import { User } from './types';

export async function updateUser(
  user: User & { adminId: UUID },
): Promise<Result<true, ApiError>> {
  const result = await mutate<T.UpdateUser, T.UpdateUserVariables>(MUTATION, {
    input: {
      id: user.id,
      adminId: user.adminId,
      name: user.name,
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotsFrequency: user.screenshotsFrequency,
      screenshotsResolution: user.screenshotsResolution,
    },
  });
  return result.mapApi(() => true);
}

const MUTATION = gql`
  mutation UpdateUser($input: UpdateUserInput!) {
    user: updateUser(input: $input) {
      id
    }
  }
`;
