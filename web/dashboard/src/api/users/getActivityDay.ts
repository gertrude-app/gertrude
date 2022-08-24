import Result from '../Result';
import { gql, query } from '../apollo';
import * as T from './__generated__/GetActivityDay';
import { entireDay } from '../helpers';

export async function getActivityDay(
  userId: string,
  day: Date,
): Promise<Result<T.GetActivityDay, ApiError>> {
  const range = entireDay(day);
  const result = await query<T.GetActivityDay, T.GetActivityDayVariables>(QUERY, {
    userId,
    before: range.end,
    after: range.start,
  });
  return result.mapErrorToApi();
}

const QUERY = gql`
  query GetActivityDay($userId: UUID!, $before: String!, $after: String!) {
    counts: getMonitoringCounts(
      userId: $userId
      ranges: [{ start: $after, end: $before }]
    ) {
      numDeleted: deletedCount
    }
    items: getMonitoringItems(userId: $userId, before: $before, after: $after) {
      __typename
      ... on CoalescedKeystrokeLine {
        id
        ids
        appName
        line
        createdAt
      }
      ... on Screenshot {
        id
        ids
        url
        width
        height
        createdAt
      }
    }
  }
`;
