import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/DeleteKeyRecord';

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
