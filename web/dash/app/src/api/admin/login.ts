import { AdminIds } from '@dash/types';
import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/LoginAdmin';

export async function login(
  email: string,
  password: string,
): Promise<Result<AdminIds, ApiError>> {
  const result = await mutate<T.LoginAdmin, T.LoginAdminVariables>(MUTATION, {
    input: { email, password },
  });
  return result.mapApi(
    (data) => ({
      id: data.token.admin.id,
      token: data.token.value,
    }),
    (errors) => {
      if (errors.some((e) => e.message.includes(`401: Unauthorized`))) {
        return { type: `actionable`, message: `Email or password incorrect.` };
      }
      return undefined;
    },
  );
}

// mutation

const MUTATION = gql`
  mutation LoginAdmin($input: LoginAdminInput!) {
    token: loginAdmin(input: $input) {
      value
      admin {
        id
      }
    }
  }
`;
