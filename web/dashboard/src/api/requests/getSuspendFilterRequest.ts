import Result from '../Result';
import { gql, query } from '../apollo';
import * as T from './__generated__/GetSuspendFilterRequest';
import { SuspendFilterRequest } from './types';

export async function getSuspendFilterRequest(
  requestId: UUID,
): Promise<Result<SuspendFilterRequest, ApiError>> {
  const result = await query<
    T.GetSuspendFilterRequest,
    T.GetSuspendFilterRequestVariables
  >(QUERY, {
    id: requestId,
  });

  return result.mapApi((data) => ({
    id: requestId,
    deviceId: data.request.device.id,
    requestedDurationInSeconds: data.request.requestedDurationInSeconds,
    requestComment: data.request.requestComment ?? undefined,
    userName: data.request.device.user.name,
    createdAt: data.request.createdAt,
    status: data.request.status,
  }));
}

const QUERY = gql`
  query GetSuspendFilterRequest($id: UUID!) {
    request: getSuspendFilterRequest(id: $id) {
      duration
      requestComment
      requestedDurationInSeconds: duration
      createdAt
      status
      device {
        id
        user {
          name
        }
      }
    }
  }
`;
