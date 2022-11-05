import type Result from '../Result';
import type * as T from './__generated__/RequestMagicLink';
import { gql, mutate } from '../apollo';

export async function requestMagicLink(email: string): Promise<Result<true, ApiError>> {
  const result = await mutate<T.RequestMagicLink, T.RequestMagicLinkVariables>(MUTATION, {
    email,
  });

  // the API always returns success for this mutation, to avoid
  // leaking whether the email address is attached to a valid account
  return result.mapApi(() => true);
}

// mutation

const MUTATION = gql`
  mutation RequestMagicLink($email: String!) {
    result: sendMagicLink(email: $email) {
      success
    }
  }
`;
