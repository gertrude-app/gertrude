import Result from '../Result';
import * as T from './__generated__/LoginAdmin';
import { gql, mutate } from '../apollo';
import { Admin } from '../../redux/slice-auth';

export async function login(
  email: string,
  password: string,
): Promise<Result<Admin, ApiError>> {
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
