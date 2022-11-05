import { AdminIds } from '@dash/types';
import Result from '../Result';
import * as T from './__generated__/HandleSignupPaymentSuccess';
import { gql, mutate } from '../apollo';

export async function handleSignupPaymentSuccess(
  stripeCheckoutSessionid: string,
): Promise<Result<AdminIds, ApiError>> {
  const result = await mutate<
    T.HandleSignupPaymentSuccess,
    T.HandleSignupPaymentSuccessVariables
  >(MUTATION, { input: { value: stripeCheckoutSessionid } });
  return result.mapApi((data) => ({
    id: data.token.admin.id,
    token: data.token.value,
  }));
}

// mutation

const MUTATION = gql`
  mutation HandleSignupPaymentSuccess($input: StringInput!) {
    token: handleSignupPaymentSuccess(input: $input) {
      value
      admin {
        id
      }
    }
  }
`;
