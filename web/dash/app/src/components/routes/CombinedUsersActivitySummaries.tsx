import React from 'react';
import { ApiErrorMessage, Loading, ActivitySummaries } from '@dash/components';
import { useQuery, Key } from '../../hooks';
import Current from '../../environment';

const CombinedUsersActivitySummariesRoute: React.FC = () => {
  const query = useQuery(Key.combinedUsersActivitySummaries, () =>
    Current.api.combinedUsersActivitySummaries(),
  );

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return (
    <ActivitySummaries
      days={query.data
        .filter((day) => day.numTotal > 0)
        .sort((a, b) => (a.date < b.date ? 1 : -1))
        .map((day, index) => ({
          date: new Date(day.date),
          numItems: day.numTotal,
          numCompleted: day.numApproved + day.numFlagged,
          numFlagged: day.numFlagged,
          index,
          numDays: query.data.length,
        }))}
    />
  );
};

export default CombinedUsersActivitySummariesRoute;
