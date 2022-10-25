import Result from '../Result';
import { gql, query } from '../apollo';
import * as T from './__generated__/UnlockRequest';

export async function getUnlockRequest(
  id: UUID,
): Promise<Result<UnlockRequest, ApiError>> {
  const result = await query<T.UnlockRequest, T.UnlockRequestVariables>(QUERY, { id });
  return result.mapApi((data) => mapUnlockRequest(data.unlockRequest));
}

export function mapUnlockRequest(req: T.UnlockRequest_unlockRequest): UnlockRequest {
  return {
    id: req.id,
    userId: req.device.user.id,
    userName: req.device.user.name,
    status: req.status,
    url: req.networkDecision.url ?? undefined,
    domain: req.networkDecision.hostname ?? undefined,
    ipAddress: req.networkDecision.ipAddress ?? undefined,
    requestComment: req.requestComment ?? undefined,
    appName: req.networkDecision.app?.displayName ?? undefined,
    appSlug: req.networkDecision.app?.slug ?? undefined,
    appBundleId: req.networkDecision.app?.bundleId ?? undefined,
    appCategories: req.networkDecision.app?.categories ?? [],
    requestProtocol: req.networkDecision.ipProtocol?.description ?? undefined,
    createdAt: req.createdAt,
  };
}

export const UNLOCK_REQUEST_FIELDS = gql`
  fragment UnlockRequestFields on UnlockRequest {
    id
    requestComment
    createdAt
    status
    networkDecision {
      ipProtocol {
        description
      }
      url
      hostname
      ipAddress
      app: appDescriptor {
        bundleId
        slug
        displayName
        categories
        shortDescription
      }
    }
    device {
      id
      user {
        id
        name
      }
    }
  }
`;

const QUERY = gql`
  ${UNLOCK_REQUEST_FIELDS}
  query UnlockRequest($id: UUID!) {
    unlockRequest: getUnlockRequest(id: $id) {
      ...UnlockRequestFields
    }
  }
`;
