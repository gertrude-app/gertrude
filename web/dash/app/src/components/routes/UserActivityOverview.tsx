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

  const reqState = request?.state;
  useEffect(() => {
    if (!reqState || reqState === `idle`) {
      dispatch(fetchActivityOverview({ userId }));
    }
  }, [dispatch, userId, reqState]);

  if (!request || request.state === `idle` || request.state === `ongoing`) {
    return <Loading />;
  }
  if (request.state === `failed`) {
    return <ApiErrorMessage error={request.error} />;
  }

  return (
    <UserActivityOverview
      userName={request.payload.user.name ?? ``}
      days={request.payload.counts.map((data) => {
        const date = new Date(data.dateRange.start);
        const loadedDay = Req.payload(days[activityDayKey(userId, date)]);
        return {
          date,
          numItems: data.numItems,
          numCompleted: loadedDay?.numDeleted ?? data.numCompleted,
        };
      })}
    />
  );
};

export default UserActivityOverviewRoute;
