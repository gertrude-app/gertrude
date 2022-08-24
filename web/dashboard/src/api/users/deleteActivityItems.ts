import Result from '../Result';
import { gql, mutate } from '../apollo';
import * as T from './__generated__/DeleteActivityItems';

export async function deleteActivityItems(
  userId: string,
  items: Array<{ id: UUID; type: 'KeystrokeLine' | 'Screenshot' }>,
): Promise<Result<T.DeleteActivityItems['items'], ApiError>> {
  const result = await mutate<T.DeleteActivityItems, T.DeleteActivityItemsVariables>(
    MUTATION,
    { userId, items },
  );
  return result.mapApi((data) => data.items);
}

const MUTATION = gql`
  mutation DeleteActivityItems($userId: UUID!, $items: [DeleteMonitoringItemInput!]!) {
    items: deleteMonitoringItems(userId: $userId, items: $items) {
      id
    }
  }
`;
