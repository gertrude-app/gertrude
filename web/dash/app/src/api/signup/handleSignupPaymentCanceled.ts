import type Result from '../Result';
import type * as T from './__generated__/HandleSignupPaymentCanceled';
import { gql, mutate } from '../apollo';

export async function handleSignupPaymentCanceled(
  stripeCheckoutSessionId: string,
): Promise<Result<true, ApiError>> {
  const result = await mutate<
    T.HandleSignupPaymentCanceled,
    T.HandleSignupPaymentCanceledVariables
  >(MUTATION, { input: { value: stripeCheckoutSessionId } });
  return result.mapApi(() => true);
}

// mutation

const MUTATION = gql`
  mutation HandleSignupPaymentCanceled($input: StringInput!) {
    response: handleSignupPaymentCanceled(input: $input) {
      success
    }
  }
`;
