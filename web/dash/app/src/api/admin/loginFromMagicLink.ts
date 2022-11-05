import { AdminIds } from '@dash/types';
import Result from '../Result';
import * as T from './__generated__/LoginFromMagicLink';
import { gql, mutate } from '../apollo';

export async function loginFromMagicLink(
  token: string,
): Promise<Result<AdminIds, ApiError>> {
  const result = await mutate<T.LoginFromMagicLink, T.LoginFromMagicLinkVariables>(
    MUTATION,
    { token },
  );
  return result.mapApi(
    (data) => ({
      id: data.adminToken.admin.id,
      token: data.adminToken.value,
    }),
    (errors) => {
      if (errors.some((e) => e.message.includes(`404: Not Found`))) {
        return { type: `actionable`, message: `Magic link token not found.` };
      }
      return undefined;
    },
  );
}

// mutation

const MUTATION = gql`
  mutation LoginFromMagicLink($token: String!) {
    adminToken: loginFromMagicLink(token: $token) {
      value
      admin {
        id
      }
    }
  }
`;
