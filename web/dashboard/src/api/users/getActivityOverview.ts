import Result from '../Result';
import { gql, query } from '../apollo';
import * as T from './__generated__/GetActivityOverview';
import { DateRangeInput } from '../../graphqlTypes';

export async function getActivityOverview(
  userId: UUID,
  ranges: DateRangeInput[] = getDateRanges(),
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

function getDateRanges(): Array<DateRangeInput> {
  const now = new Date();
  const ranges: Array<DateRangeInput> = [];
  for (let i = 0; i < NUM_MONITORING_DAYS; i++) {
    const start = new Date();
    start.setDate(now.getDate() - i);
    mutateToDayBegin(start);
    const end = new Date();
    end.setDate(now.getDate() - i);
    mutateToDayEnd(end);
    ranges.push({ start: start.toISOString(), end: end.toISOString() });
  }
  return ranges;
}

const NUM_MONITORING_DAYS = 14;

function mutateToDayEnd(date: Date): void {
  date.setHours(23);
  date.setMinutes(59);
  date.setSeconds(59);
  date.setMilliseconds(999);
}

function mutateToDayBegin(date: Date): void {
  date.setHours(0);
  date.setMinutes(0);
  date.setSeconds(0);
  date.setMilliseconds(0);
}
