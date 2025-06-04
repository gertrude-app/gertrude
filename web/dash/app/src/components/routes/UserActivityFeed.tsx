import { ApiErrorMessage, Loading, UserActivityFeed } from '@dash/components';
import { dateFromUrl } from '@dash/datetime';
import { Result } from '@dash/types';
import React from 'react';
import { useParams } from 'react-router-dom';
import Current from '../../environment';
import { Key, useMutation, useOptimism, useQuery } from '../../hooks';
import { entireDay } from '../../lib/days';
import * as lib from '../../lib/user-activity';

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
      const [input, nextState] = lib.prepareUserActivityDelete(rootIds, data);
      optimistic.update(queryKey, nextState);
      return Current.api.deleteActivityItems(input);
    },
    {
      invalidating: [queryKey, Key.childActivitySummaries(userId), Key.dashboard],
      toast: `delete:activity-items`,
    },
  );

  const flagItem = useMutation(
    (rootId: UUID) => {
      const data = query.data;
      if (!data) return Result.resolveUnexpected(`816ec66f`);
      const [input, nextState] = lib.flagUserActivityFeedItem(rootId, data);
      optimistic.update(queryKey, nextState);
      return Current.api.flagActivityItems(input);
    },
    {
      invalidating: [queryKey, Key.childActivitySummaries(userId), Key.dashboard],
      toast: `flag:activity-item`,
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
      flagItem={(rootId) => flagItem.mutate(rootId)}
      items={query.data.items
        .map(lib.outputItemToActivityFeedItem)
        .filter((item) => !item.deleted)}
      highlightSuspensionActivity={query.data.showSuspensionActivity}
    />
  );
};

export default UserActivityFeedRoute;
