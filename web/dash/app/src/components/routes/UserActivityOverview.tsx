import React, { useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { ApiErrorMessage, Loading, UserActivityOverview } from '@dash/components';
import { useDispatch, useSelector } from '../../redux/hooks';
import { activityDayKey, fetchActivityOverview } from '../../redux/slice-users';
import { Req } from '../../redux/helpers';

const UserActivityOverviewRoute: React.FC = () => {
  const { userId = `` } = useParams<{ userId: string }>();
  const dispatch = useDispatch();
  const { request, days } = useSelector((state) => ({
    request: state.users.activityOverviews[userId],
    days: state.users.activityDays,
  }));

  useEffect(() => {
    if (!request?.state || request?.state === `idle`) {
      dispatch(fetchActivityOverview({ userId }));
    }
  }, [dispatch, userId, request?.state]);

  if (!request || request.state === `idle` || request.state === `ongoing`) {
    return <Loading />;
  }
  if (request.state === `failed`) {
    return <ApiErrorMessage error={request.error} />;
  }

  return (
    <UserActivityOverview
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

export default UserActivityOverviewRoute;
