import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/VerifySignupEmail';

export async function verifySignupEmail(token: UUID): Promise<Result<UUID, ApiError>> {
  const result = await mutate<T.VerifySignupEmail, T.VerifySignupEmailVariables>(
    MUTATION,
    { input: { uuid: token } },
  );
  return result.mapApi((data) => data.admin.id);
}

// mutation

const MUTATION = gql`
  mutation VerifySignupEmail($input: UUIDInput!) {
    admin: verifyEmail(input: $input) {
      id
    }
  }
`;
