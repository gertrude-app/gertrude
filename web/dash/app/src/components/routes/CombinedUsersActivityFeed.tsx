import { Result } from '@dash/types';
import { useParams } from 'react-router-dom';
import { dateFromUrl } from '@dash/datetime';
import { CombinedUsersActivityFeed, ApiErrorMessage, Loading } from '@dash/components';
import React from 'react';
import { useOptimism, Key, useMutation, useQuery } from '../../hooks';
import Current from '../../environment';
import { entireDay } from '../../lib/days';
import {
  outputItemToActivityFeedItem,
  prepareCombinedUsersActivityDelete,
} from '../../lib/user-activity';

const CombinedUsersActivityFeedRoute: React.FC = () => {
  const { urlDate = `` } = useParams<{ urlDate: string }>();
  const date = dateFromUrl(urlDate);
  const optimistic = useOptimism();
  const queryKey = Key.combinedUsersActivityFeed(urlDate);

  const query = useQuery(queryKey, () =>
    Current.api.combinedUsersActivityFeed({ range: entireDay(date) }),
  );

  const deleteItems = useMutation(
    (rootIds: UUID[]) => {
      const data = query.data;
      if (!data) return Result.resolveUnexpected(`af6a2372`);
      const [input, nextState] = prepareCombinedUsersActivityDelete(rootIds, data);
      optimistic.update(queryKey, nextState);
      return Current.api.deleteActivityItems(input);
    },
    {
      invalidating: [Key.combinedUsersActivitySummaries],
      toast: `delete:activity-items`,
    },
  );

  if (query.isLoading) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return (
    <CombinedUsersActivityFeed
      date={date}
      activity={query.data
        .filter((user) => user.items.length > 0)
        .sort((a, b) => (a.items.length > b.items.length ? -1 : 1))
        .map((user) => ({
          userName: user.userName,
          items: user.items.map(outputItemToActivityFeedItem),
        }))}
      numDeleted={query.data.reduce((acc, user) => acc + user.numDeleted, 0)}
      deleteItems={(rootIds) => deleteItems.mutate(rootIds)}
    />
  );
};

export default CombinedUsersActivityFeedRoute;
