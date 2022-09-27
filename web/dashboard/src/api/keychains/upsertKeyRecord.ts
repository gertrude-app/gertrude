import { UpdateKeyRecordInput } from '@dashboard/types/GraphQL';
import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as U from './__generated__/UpdateKeyRecord';
import * as C from './__generated__/CreateKeyRecord';

export async function upsertKeyRecord(
  keyRecord: Editable<KeyRecord>,
): Promise<Result<true, ApiError>> {
  const input: UpdateKeyRecordInput = {
    id: keyRecord.original.id,
    keychainId: keyRecord.draft.keychainId,
    key: JSON.stringify(keyRecord.draft.key),
    comment: keyRecord.draft.comment,
    deletedAt: keyRecord.draft.expiration,
  };

  const result = keyRecord.isNew
    ? await mutate<C.CreateKeyRecord, C.CreateKeyRecordVariables>(CREATE_MUTATION, {
        input,
      })
    : await mutate<U.UpdateKeyRecord, U.UpdateKeyRecordVariables>(UPDATE_MUTATION, {
        input,
      });

  return result.mapApi(() => true);
}

const UPDATE_MUTATION = gql`
  mutation UpdateKeyRecord($input: UpdateKeyRecordInput!) {
    keyRecord: updateKeyRecord(input: $input) {
      id
    }
  }
`;

const CREATE_MUTATION = gql`
  mutation CreateKeyRecord($input: CreateKeyRecordInput!) {
    keyRecord: createKeyRecord(input: $input) {
      id
    }
  }
`;
