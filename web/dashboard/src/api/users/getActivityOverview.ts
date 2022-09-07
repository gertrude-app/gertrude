import { DateRangeInput } from '@dashboard/types/GraphQL';
import Result from '../Result';
import { gql, query } from '../apollo';
import * as T from './__generated__/GetActivityOverview';
import { entireDay } from '../helpers';

export async function getActivityOverview(
  userId: UUID,
  ranges: DateRangeInput[] = entireDays(14),
): Promise<Result<T.GetActivityOverview, ApiError>> {
  const result = await query<T.GetActivityOverview, T.GetActivityOverviewVariables>(
    QUERY,
    { userId, ranges },
  );
  return result.mapErrorToApi();
}

const QUERY = gql`
  query GetActivityOverview($userId: UUID!, $ranges: [DateRangeInput!]!) {
    user: getUser(id: $userId) {
      name
    }
    counts: getMonitoringCounts(userId: $userId, ranges: $ranges) {
      dateRange {
        start
      }
      numCompleted: deletedCount
      numItems: total
    }
  }
`;

// helpers

function entireDays(numDays: number): DateRangeInput[] {
  const now = new Date();
  const ranges: DateRangeInput[] = [];
  for (let i = 0; i < numDays; i++) {
    const day = new Date(now.getTime());
    day.setDate(now.getDate() - i);
    ranges.push(entireDay(day));
  }
  return ranges;
}
