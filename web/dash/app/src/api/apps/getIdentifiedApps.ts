import type Result from '../Result';
import type * as T from './__generated__/GetIdentifiedApps';
import { gql, query } from '../apollo';

export async function getIdentifiedApps(): Promise<
  Result<T.GetIdentifiedApps_apps[], ApiError>
> {
  const result = await query<T.GetIdentifiedApps>(QUERY);
  return result.mapApi((data) => data.apps);
}

const QUERY = gql`
  query GetIdentifiedApps {
    apps: getIdentifiedApps {
      id
      name
      slug
      selectable
      bundleIds {
        id
        bundleId
      }
      category {
        id
        name
        slug
      }
    }
  }
`;
