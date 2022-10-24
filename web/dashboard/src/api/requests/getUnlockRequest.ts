import Result from '../Result';
import { gql, query } from '../apollo';
import * as T from './__generated__/UnlockRequest';

export async function getUnlockRequest(
  id: UUID,
): Promise<Result<UnlockRequest, ApiError>> {
  const result = await query<T.UnlockRequest, T.UnlockRequestVariables>(QUERY, { id });
  return result.mapApi(({ unlockRequest: req }) => ({
    id: req.id,
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
  }));
}

const QUERY = gql`
  query UnlockRequest($id: UUID!) {
    unlockRequest: getUnlockRequest(id: $id) {
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
          name
        }
      }
    }
  }
`;
