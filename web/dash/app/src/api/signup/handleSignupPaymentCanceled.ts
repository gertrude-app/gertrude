import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/HandleSignupPaymentCanceled';

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
