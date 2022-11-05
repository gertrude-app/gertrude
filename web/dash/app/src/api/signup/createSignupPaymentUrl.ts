import type Result from '../Result';
import type * as T from './__generated__/CreateSignupPaymentUrl';
import { gql, mutate } from '../apollo';

export async function createSignupPaymentUrl(
  adminId: UUID,
): Promise<Result<string, ApiError>> {
  const result = await mutate<
    T.CreateSignupPaymentUrl,
    T.CreateSignupPaymentUrlVariables
  >(MUTATION, { input: { uuid: adminId } });
  return result.mapApi((data) => data.payment.url);
}

// mutation

const MUTATION = gql`
  mutation CreateSignupPaymentUrl($input: UUIDInput!) {
    payment: createSignupPaymentUrl(input: $input) {
      url
    }
  }
`;
