import Result from '../Result';
import { gql, query } from '../apollo';
import * as T from './__generated__/AllowingSignups';

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
