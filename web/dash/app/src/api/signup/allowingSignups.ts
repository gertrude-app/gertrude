import type Result from '../Result';
import type * as T from './__generated__/AllowingSignups';
import { gql, query } from '../apollo';

export async function allowingSignups(): Promise<Result<boolean, ApiError>> {
  const result = await query<T.AllowingSignups>(QUERY);
  return result.mapApi((data) => data.result.success);
}

// mutation

const QUERY = gql`
  query AllowingSignups {
    result: allowingSignups {
      success
    }
  }
`;
