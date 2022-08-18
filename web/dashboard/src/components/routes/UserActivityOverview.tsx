import React, { useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { OverviewScreen } from '@shared/dashboard/UserActivity/Overview';
import { useDispatch, useSelector } from '../../redux/hooks';
import ApiErrorMessage from '../ApiErrorMessage';
import Loading from '@shared/Loading';
import { fetchActivityOverview } from '../../redux/slice-users';

const UserActivityOverview: React.FC = () => {
  const { userId = `` } = useParams<{ userId: string }>();
  const dispatch = useDispatch();
  const request = useSelector((state) => state.users.activityOverviews[userId]);

  useEffect(() => {
    dispatch(fetchActivityOverview(userId));
  }, [dispatch, userId]);

  if (!request || request.state === `idle` || request.state === `ongoing`) {
    return <Loading />;
  }
  if (request.state === `failed`) {
    return <ApiErrorMessage error={request.error} />;
  }

  return (
    <OverviewScreen
      userName={request.payload.user.name ?? ``}
      days={request.payload.counts.map((data) => ({
        date: new Date(data.dateRange.start),
        numItems: data.numItems,
        numCompleted: data.numCompleted,
      }))}
    />
  );
};

export default UserActivityOverview;
