import { ApiErrorMessage, FamilyActivityFeed, Loading } from '@dash/components';
import { dateFromUrl } from '@dash/datetime';
import { Result } from '@dash/types';
import React from 'react';
import { useParams } from 'react-router-dom';
import Current from '../../environment';
import { Key, useMutation, useOptimism, useQuery } from '../../hooks';
import { entireDay } from '../../lib/days';
import * as lib from '../../lib/user-activity';

const FamilyActivityFeedRoute: React.FC = () => {
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
      const [input, nextState] = lib.prepareCombinedUsersActivityDelete(rootIds, data);
      optimistic.update(queryKey, nextState);
      return Current.api.deleteActivityItems(input);
    },
    {
      invalidating: [Key.familyActivitySummaries],
      toast: `delete:activity-items`,
    },
  );

  const flagItem = useMutation(
    (rootId: UUID) => {
      const data = query.data;
      if (!data) return Result.resolveUnexpected(`07d2dbbf`);
      const [input, nextState] = lib.flagCombinedActivityFeedItem(rootId, data);
      optimistic.update(queryKey, nextState);
      return Current.api.flagActivityItems(input);
    },
    {
      invalidating: [Key.familyActivitySummaries],
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
    <FamilyActivityFeed
      date={date}
      activity={query.data
        .filter((user) => user.items.length > 0)
        .map((user) => ({
          userName: user.userName,
          highlightSuspensionActivity: user.showSuspensionActivity,
          items: user.items.map(lib.outputItemToActivityFeedItem),
        }))}
      numDeleted={query.data.reduce((acc, user) => acc + user.numDeleted, 0)}
      deleteItems={(rootIds) => deleteItems.mutate(rootIds)}
      flagItem={(rootId) => flagItem.mutate(rootId)}
    />
  );
};

export default FamilyActivityFeedRoute;
