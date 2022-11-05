import type Result from '../Result';
import type * as T from './__generated__/CreatePendingAppConnection';
import { gql, mutate } from '../apollo';

export async function createPendingAppConnection(
  userId: UUID,
): Promise<Result<number, ApiError>> {
  const result = await mutate<
    T.CreatePendingAppConnection,
    T.CreatePendingAppConnectionVariables
  >(CREATE_MUTATION, { input: { uuid: userId } });
  return result.mapApi((data) => data.connection.code);
}

const CREATE_MUTATION = gql`
  mutation CreatePendingAppConnection($input: UUIDInput!) {
    connection: createPendingAppConnection(input: $input) {
      code
    }
  }
`;
