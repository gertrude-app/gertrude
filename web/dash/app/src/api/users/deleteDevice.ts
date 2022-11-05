import type Result from '../Result';
import type * as T from './__generated__/DeleteDevice';
import { gql, mutate } from '../apollo';

export async function deleteDevice(id: UUID): Promise<Result<true, ApiError>> {
  const result = await mutate<T.DeleteDevice, T.DeleteDeviceVariables>(MUTATION, { id });
  return result.mapApi(() => true);
}

const MUTATION = gql`
  mutation DeleteDevice($id: UUID!) {
    device: deleteDevice(id: $id) {
      id
    }
  }
`;
