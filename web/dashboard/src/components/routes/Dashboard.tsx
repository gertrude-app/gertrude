import React, { useEffect } from 'react';
import Loading from '@shared/Loading';
import WidgetsContainer from '@shared/dashboard/Widgets/WidgetsContainer';
import { useDispatch, useSelector } from '../../redux/hooks';
import { QueryProps } from '../../redux/store';
import { Req, Query } from '../../redux/helpers';
import { fetchDashboardData } from '../../redux/slice-dashboard';
import ApiErrorMessage from '../ApiErrorMessage';

const Dashboard: React.FC = () => {
  const dispatch = useDispatch();
  const [query, shouldFetch] = useSelector(queryProps(dispatch));

  useEffect(() => {
    if (shouldFetch) {
      dispatch(fetchDashboardData());
    }
  }, [dispatch, shouldFetch]);

  if (
    query.state === `shouldFetch` ||
    query.state === `ongoing` ||
    query.state === `entityDeleted`
  ) {
    return <Loading />;
  }

  if (query.state === `failed`) {
    return <ApiErrorMessage error={query.error} />;
  }

  return <WidgetsContainer {...query.props} />;
};

export default Dashboard;

export const queryProps: QueryProps<typeof WidgetsContainer> = () => (state) => {
  const request = state.dashboard.request;
  if (request.state !== `succeeded`) {
    return [Req.toUnresolvedQuery(request), request.state !== `failed`];
  }
  return [Query.resolve(request.payload), false];
};
