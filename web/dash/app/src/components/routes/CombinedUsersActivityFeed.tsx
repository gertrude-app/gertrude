import React, { useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { dateFromUrl } from '@dash/datetime';
import { typesafe } from '@shared/ts-utils';
import { CombinedUsersActivityFeed, ApiErrorMessage, Loading } from '@dash/components';
import type { ActivityFeedItem } from '@dash/components';
import { useDispatch, useSelector } from '../../redux/hooks';
import {
  deleteActivityItems,
  fetchCombinedUsersActivityFeed,
} from '../../redux/slice-users';

const CombinedUsersActivityFeedRoute: React.FC = () => {
  const { date = `` } = useParams<{ date: string }>();
  const day = dateFromUrl(date);
  const dispatch = useDispatch();
  const request = useSelector(
    (state) => state.users.fetchCombinedUsersActivityFeed[date],
  );
  const allActivity = useSelector((state) => state.users.userActivityFeedDays);

  useEffect(() => {
    if (!request?.state || request?.state === `idle`) {
      dispatch(fetchCombinedUsersActivityFeed(day));
    }
  }, [dispatch, day, request?.state]);

  if (!request || request.state === `idle` || request.state === `ongoing`) {
    return <Loading />;
  }

  if (request.state === `failed`) {
    return <ApiErrorMessage error={request.error} />;
  }

  const activity: Record<string, ActivityFeedItem[]> = {};
  let numDeleted = 0;

  for (const [activityDayKey, activityRequest] of typesafe.objectEntries(allActivity)) {
    if (activityRequest.state !== `succeeded`) {
      continue;
    }

    if (activityDayKey.endsWith(date)) {
      const payload = activityRequest.payload;

      activity[payload.userName] = typesafe
        .objectValues(payload.items)
        .filter((item) => !item.deleted);
      numDeleted += payload.numDeleted;
    }
  }

  return (
    <CombinedUsersActivityFeed
      date={day}
      activity={activity}
      numDeleted={numDeleted}
      deleteItems={(itemRootIds) =>
        dispatch(deleteActivityItems({ date: day, itemRootIds }))
      }
    />
  );
};

export default CombinedUsersActivityFeedRoute;
