import { UpdateKeychainInput } from '@dashboard/types/GraphQL';
import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as U from './__generated__/UpdateKeychain';
import * as C from './__generated__/CreateKeychain';

export async function upsertKeychain(
  keychain: Editable<Keychain> & { adminId: UUID },
): Promise<Result<true, ApiError>> {
  const input: UpdateKeychainInput = {
    id: keychain.draft.id,
    name: keychain.draft.name,
    description: keychain.draft.description,
    authorId: keychain.adminId,
    isPublic: keychain.draft.isPublic,
  };

  const result = keychain.isNew
    ? await mutate<C.CreateKeychain, C.CreateKeychainVariables>(CREATE_MUTATION, {
        input,
      })
    : await mutate<U.UpdateKeychain, U.UpdateKeychainVariables>(UPDATE_MUTATION, {
        input,
      });

  return result.mapApi(() => true);
}

const CREATE_MUTATION = gql`
  mutation CreateKeychain($input: CreateKeychainInput!) {
    keychain: createKeychain(input: $input) {
      id
    }
  }
`;

const UPDATE_MUTATION = gql`
  mutation UpdateKeychain($input: UpdateKeychainInput!) {
    notification: updateKeychain(input: $input) {
      id
    }
  }
`;
