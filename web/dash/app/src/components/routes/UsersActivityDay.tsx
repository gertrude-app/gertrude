import React, { useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { dateFromUrl, formatDate } from '@dash/datetime';
import { typesafe } from '@shared/ts-utils';
import { AllUsersActivityReviewDay, ApiErrorMessage, Loading } from '@dash/components';
import type { ActivityItem } from '@dash/components';
import { useDispatch, useSelector } from '../../redux/hooks';
import { deleteActivityItems, fetchUsersActivityDay } from '../../redux/slice-users';

const UsersActivityDay: React.FC = () => {
  const { date = `` } = useParams<{ date: string }>();
  const day = dateFromUrl(date);
  const dispatch = useDispatch();
  const request = useSelector((state) => state.users.fetchAllUsersDay[date]);
  const allActivity = useSelector((state) => state.users.activityDays);

  useEffect(() => {
    if (!request?.state || request?.state === `idle`) {
      dispatch(fetchUsersActivityDay(day));
    }
  }, [dispatch, day, request?.state]);

  if (!request || request.state === `idle` || request.state === `ongoing`) {
    return <Loading />;
  }

  if (request.state === `failed`) {
    return <ApiErrorMessage error={request.error} />;
  }

  const activity: Record<string, ActivityItem[]> = {};
  let numDeleted = 0;

  for (const [activityDayKey, activityRequest] of typesafe.objectEntries(allActivity)) {
    if (activityRequest.state !== `succeeded`) {
      continue;
    }

    if (activityDayKey.endsWith(date)) {
      const payload = activityRequest.payload;

      activity[payload.userName] = typesafe.objectValues(payload.items);
      numDeleted += payload.numDeleted;
    }
  }

  return (
    <AllUsersActivityReviewDay
      date={day}
      activity={activity}
      numDeleted={numDeleted}
      deleteItems={(itemRootIds) =>
        dispatch(deleteActivityItems({ date: day, itemRootIds }))
      }
    />
  );
};

export default UsersActivityDay;
