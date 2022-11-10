import type { UnlockRequest } from '@dash/types';
import type Result from '../Result';
import type * as T from './__generated__/UsersUnlockRequests';
import { gql, query } from '../apollo';
import { mapUnlockRequest, UNLOCK_REQUEST_FIELDS } from './getUnlockRequest';

export async function getUsersUnlockRequests(): Promise<
  Result<UnlockRequest[], ApiError>
> {
  const result = await query<T.UsersUnlockRequests>(QUERY);
  return result.mapApi((data) => data.unlockRequests.map(mapUnlockRequest));
}

const QUERY = gql`
  ${UNLOCK_REQUEST_FIELDS}
  query UsersUnlockRequests {
    unlockRequests: getAdminUnlockRequests {
      ...UnlockRequestFields
    }
  }
`;
