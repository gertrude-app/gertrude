import Result from '../Result';
import * as T from './__generated__/InitiateSignup';
import { gql, mutate } from '../apollo';

export async function sendVerificationEmail(
  email: string,
): Promise<Result<true, ApiError>> {
  const result = await mutate<T.InitiateSignup, T.InitiateSignupVariables>(MUTATION, {
    input: { email },
  });
  return result.mapApi(() => true);
}

// mutation

const MUTATION = gql`
  mutation InitiateSignup($input: EmailInput!) {
    result: initiateSignup(input: $input) {
      success
    }
  }
`;
