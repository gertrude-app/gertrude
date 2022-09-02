import React, { useEffect } from 'react';
import { useParams } from 'react-router-dom';
import ActivityOverview from '@dashboard/Users/Activity/Overview';
import Loading from '@shared/Loading';
import { useDispatch, useSelector } from '../../redux/hooks';
import ApiErrorMessage from '../ApiErrorMessage';
import { fetchActivityOverview } from '../../redux/slice-users';

const UserActivityOverview: React.FC = () => {
  const { userId = `` } = useParams<{ userId: string }>();
  const dispatch = useDispatch();
  const request = useSelector((state) => state.users.activityOverviews[userId]);

  useEffect(() => {
    dispatch(fetchActivityOverview({ userId }));
  }, [dispatch, userId]);

  if (!request || request.state === `idle` || request.state === `ongoing`) {
    return <Loading />;
  }
  if (request.state === `failed`) {
    return <ApiErrorMessage error={request.error} />;
  }

  return (
    <ActivityOverview
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
