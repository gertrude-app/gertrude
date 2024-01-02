import React from 'react';
import { useParams } from 'react-router-dom';
import { dateFromUrl } from '@dash/datetime';
import { ApiErrorMessage, Loading, UserActivityFeed } from '@dash/components';
import { Result } from '@dash/types';
import Current from '../../environment';
import { useQuery, Key, useMutation, useOptimism } from '../../hooks';
import { entireDay } from '../../lib/days';
import {
  outputItemToActivityFeedItem,
  prepareUserActivityDelete,
} from '../../lib/user-activity';

const UserActivityFeedRoute: React.FC = () => {
  const { userId = ``, urlDate = `` } = useParams<{ userId: string; urlDate: string }>();
  const date = dateFromUrl(urlDate);
  const optimistic = useOptimism();
  const queryKey = Key.userActivityFeed(userId, urlDate);

  const query = useQuery(queryKey, () =>
    Current.api.userActivityFeed({ userId, range: entireDay(date) }),
  );

  const deleteItems = useMutation(
    (rootIds: UUID[]) => {
      const data = query.data;
      if (!data) return Result.resolveUnexpected(`c86706e8`);
      const [input, nextState] = prepareUserActivityDelete(rootIds, data);
      optimistic.update(queryKey, nextState);
      return Current.api.deleteActivityItems(input);
    },
    {
      invalidating: [queryKey, Key.userActivitySummaries(userId), Key.dashboard],
      toast: `delete:activity-items`,
    },
  );

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return (
    <UserActivityFeed
      date={date}
      numDeleted={query.data.numDeleted}
      deleteItems={(rootIds) => deleteItems.mutate(rootIds)}
      items={query.data.items
        .map(outputItemToActivityFeedItem)
        .filter((item) => !item.deleted)}
      highlightSuspensionActivity={query.data.showSuspensionActivity}
    />
  );
};

export default UserActivityFeedRoute;
