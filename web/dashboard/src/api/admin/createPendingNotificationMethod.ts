import { AdminNotificationMethod } from '@dashboard/types/Admin';
import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/CreatePendingNotificationMethod';

export async function createPendingNotificationMethod(
  data: AdminNotificationMethod['data'],
): Promise<Result<UUID, ApiError>> {
  const result = await mutate<
    T.CreatePendingNotificationMethod,
    T.CreatePendingNotificationMethodVariables
  >(MUTATION, { json: toServerJson(data) });
  return result.mapApi((data) => data.method.id);
}

const MUTATION = gql`
  mutation CreatePendingNotificationMethod($json: String!) {
    method: createPendingAdminNotificationMethod(json: $json) {
      id
    }
  }
`;

// 😕 this is a sort of brittle hardcoded API integration touchpoint
// better would be to figure out some graphql _union_ of inputs...
function toServerJson(data: AdminNotificationMethod['data']): string {
  switch (data.type) {
    case `email`:
      return JSON.stringify({ email: { email: data.email } });
    case `text`:
      return JSON.stringify({ text: { phoneNumber: data.phoneNumber } });
    case `slack`:
      return JSON.stringify({
        slack: {
          token: data.token,
          channelName: data.channelName,
          channelId: data.channelId,
        },
      });
  }
}
