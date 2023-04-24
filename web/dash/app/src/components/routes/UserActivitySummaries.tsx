import React, { useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { ApiErrorMessage, Loading, ActivitySummaries } from '@dash/components';
import { useDispatch, useSelector } from '../../redux/hooks';
import { activityDayKey, fetchUserActivitySummaries } from '../../redux/slice-users';
import { Req } from '../../redux/helpers';

const UserActivitySummariesRoute: React.FC = () => {
  const { userId = `` } = useParams<{ userId: string }>();
  const dispatch = useDispatch();
  const { request, days } = useSelector((state) => ({
    request: state.users.userActivitySummaries[userId],
    days: state.users.userActivityFeedDays,
  }));

  useEffect(() => {
    if (!request?.state || request?.state === `idle`) {
      dispatch(fetchUserActivitySummaries({ userId }));
    }
  }, [dispatch, userId, request?.state]);

  if (!request || request.state === `idle` || request.state === `ongoing`) {
    return <Loading />;
  }
  if (request.state === `failed`) {
    return <ApiErrorMessage error={request.error} />;
  }

  return (
    <ActivitySummaries
      userName={request.payload.userName}
      days={request.payload.days.map((day, index) => {
        const date = new Date(day.date);
        const loadedDay = Req.payload(days[activityDayKey(userId, date)]);
        return {
          date,
          numItems: day.totalItems,
          numCompleted: loadedDay?.numDeleted ?? day.numApproved,
          index,
          numDays: request.payload.days.length,
        };
      })}
    />
  );
};

export default UserActivitySummariesRoute;
