import type { UpdateUserInput } from '@dash/types';
import type Result from '../Result';
import type * as U from './__generated__/UpdateUser';
import type * as C from './__generated__/CreateUser';
import type { User } from './types';
import { gql, mutate } from '../apollo';

export async function upsertUser(
  user: User & { adminId: UUID; isNew?: boolean },
): Promise<Result<true, ApiError>> {
  const input: UpdateUserInput = {
    id: user.id,
    adminId: user.adminId,
    name: user.name,
    keyloggingEnabled: user.keyloggingEnabled,
    screenshotsEnabled: user.screenshotsEnabled,
    screenshotsFrequency: user.screenshotsFrequency,
    screenshotsResolution: user.screenshotsResolution,
  };

  const result = user.isNew
    ? await mutate<C.CreateUser, C.CreateUserVariables>(CREATE_MUTATION, {
        input,
      })
    : await mutate<U.UpdateUser, U.UpdateUserVariables>(UPDATE_MUTATION, {
        input,
      });

  return result.mapApi(() => true);
}

const CREATE_MUTATION = gql`
  mutation CreateUser($input: CreateUserInput!) {
    user: createUser(input: $input) {
      id
    }
  }
`;

const UPDATE_MUTATION = gql`
  mutation UpdateUser($input: UpdateUserInput!) {
    user: updateUser(input: $input) {
      id
    }
  }
`;
