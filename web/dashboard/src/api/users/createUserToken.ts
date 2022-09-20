import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/CreateUserToken';

export async function createUserToken(userId: UUID): Promise<Result<UUID, ApiError>> {
  const result = await mutate<T.CreateUserToken, T.CreateUserTokenVariables>(
    CREATE_MUTATION,
    { input: { userId } },
  );
  return result.mapApi((data) => data.token.value);
}

const CREATE_MUTATION = gql`
  mutation CreateUserToken($input: CreateUserTokenInput!) {
    token: createUserToken(input: $input) {
      value
    }
  }
`;
