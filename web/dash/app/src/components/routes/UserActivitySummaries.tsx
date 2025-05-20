import React from 'react';
import { useParams } from 'react-router-dom';
import { ApiErrorMessage, Loading, ActivitySummaries } from '@dash/components';
import { useQuery, Key } from '../../hooks';
import Current from '../../environment';

const UserActivitySummariesRoute: React.FC = () => {
  const { userId = `` } = useParams<{ userId: string }>();

  const getSummaries = useQuery(Key.userActivitySummaries(userId), () =>
    Current.api.userActivitySummaries(userId),
  );

  if (getSummaries.isPending) {
    return <Loading />;
  }

  if (getSummaries.isError) {
    return <ApiErrorMessage error={getSummaries.error} />;
  }

  const summaries = getSummaries.data;

  return (
    <ActivitySummaries
      userName={summaries.userName}
      days={summaries.days
        .filter((day) => day.numTotal > 0)
        .sort((a, b) => (a.date < b.date ? 1 : -1))
        .map((day, index) => ({
          date: new Date(day.date),
          numItems: day.numTotal,
          numCompleted: day.numApproved + day.numFlagged,
          numFlagged: day.numFlagged,
          index,
          numDays: summaries.days.length,
        }))}
    />
  );
};

export default UserActivitySummariesRoute;
