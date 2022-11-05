import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/InitiateSignup';

export async function initiateSignup(
  email: string,
  password: string,
): Promise<Result<string | null, ApiError>> {
  const result = await mutate<T.InitiateSignup, T.InitiateSignupVariables>(MUTATION, {
    input: { email, password },
  });
  return result.mapApi((data) => data.result.url);
}

// mutation

const MUTATION = gql`
  mutation InitiateSignup($input: InitiateSignupInput!) {
    result: initiateSignup(input: $input) {
      url
    }
  }
`;
