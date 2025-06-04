import { ActivitySummaries, ApiErrorMessage, Loading } from '@dash/components';
import React from 'react';
import { useParams } from 'react-router-dom';
import Current from '../../environment';
import { Key, useQuery } from '../../hooks';

const ChildActivitySummariesRoute: React.FC = () => {
  const { userId = `` } = useParams<{ userId: string }>();

  const getSummaries = useQuery(Key.childActivitySummaries(userId), () =>
    Current.api.childActivitySummaries({
      childId: userId,
      jsTimezoneOffsetMinutes: new Date().getTimezoneOffset(),
    }),
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
      userName={summaries.childName}
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

export default ChildActivitySummariesRoute;
