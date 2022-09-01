import Result from '../Result';
import * as T from './__generated__/ListAdminKeychains';
import { gql, mutate } from '../apollo';

export async function listKeychains(): Promise<
  Result<T.ListAdminKeychains['keychains'], ApiError>
> {
  const result = await mutate<T.ListAdminKeychains>(MUTATION);
  return result.mapApi((data) => data.keychains);
}

// mutation

const MUTATION = gql`
  query ListAdminKeychains {
    keychains: getAdminKeychains {
      id
      name
      description
      isPublic
      authorId
      keys {
        id
      }
    }
  }
`;
