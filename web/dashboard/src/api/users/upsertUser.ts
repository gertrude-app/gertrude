import { isUnsaved } from '@dashboard/lib/id';
import { UpdateUserInput } from '@dashboard/types/GraphQL';
import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as U from './__generated__/UpdateUser';
import * as C from './__generated__/CreateUser';
import { User } from './types';

export async function upsertUser(
  user: User & { adminId: UUID },
): Promise<Result<UUID, ApiError>> {
  const input: Omit<UpdateUserInput, 'id'> = {
    adminId: user.adminId,
    name: user.name,
    keyloggingEnabled: user.keyloggingEnabled,
    screenshotsEnabled: user.screenshotsEnabled,
    screenshotsFrequency: user.screenshotsFrequency,
    screenshotsResolution: user.screenshotsResolution,
  };

  const result = isUnsaved(user.id)
    ? await mutate<C.CreateUser, C.CreateUserVariables>(CREATE_MUTATION, {
        input,
      })
    : await mutate<U.UpdateUser, U.UpdateUserVariables>(UPDATE_MUTATION, {
        input: { ...input, id: user.id },
      });

  return result.mapApi((data) => data.user.id);
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
