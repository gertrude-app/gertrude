import type Result from '../Result';
import type * as T from './__generated__/DeleteKeyRecord';
import { gql, mutate } from '../apollo';

export async function deleteKeyRecord(id: UUID): Promise<Result<true, ApiError>> {
  const result = await mutate<T.DeleteKeyRecord, T.DeleteKeyRecordVariables>(MUTATION, {
    id,
  });
  return result.mapApi(() => true);
}

const MUTATION = gql`
  mutation DeleteKeyRecord($id: UUID!) {
    key: deleteKeyRecord(id: $id) {
      id
    }
  }
`;
