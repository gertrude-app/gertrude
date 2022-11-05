import type { UpdateKeychainInput } from '@dash/types';
import type { Keychain } from '@dash/keys';
import type Result from '../Result';
import type * as U from './__generated__/UpdateKeychain';
import type * as C from './__generated__/CreateKeychain';
import { gql, mutate } from '../apollo';

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
