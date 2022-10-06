import React, { useEffect } from 'react';
import { v4 as uuid } from 'uuid';
import Loading from '@shared/Loading';
import Dashboard from '@dashboard/Dashboard';
import { useDispatch, useSelector } from '../../redux/hooks';
import { QueryProps } from '../../redux/store';
import { Req, Query } from '../../redux/helpers';
import { fetchDashboardData } from '../../redux/slice-dashboard';
import { createKeychainInitiated } from '../../redux/slice-keychains';
import ApiErrorMessage from '../ApiErrorMessage';

const DashboardRoute: React.FC = () => {
  const dispatch = useDispatch();
  const [query, shouldFetch] = useSelector(queryProps(dispatch));

  useEffect(() => {
    if (shouldFetch) {
      dispatch(fetchDashboardData());
    }
  }, [dispatch, shouldFetch]);

  if (query.state !== `resolved` && query.state !== `failed`) {
    return <Loading />;
  }

  if (query.state === `failed`) {
    return <ApiErrorMessage error={query.error} />;
  }

  return <Dashboard {...query.props} />;
};

export default DashboardRoute;

export const queryProps: QueryProps<typeof Dashboard> = (dispatch) => (state) => {
  const adminId = state.auth.admin?.id ?? ``;
  const request = state.dashboard.request;
  if (request.state !== `succeeded`) {
    return [Req.toUnresolvedQuery(request), request.state !== `failed`];
  }
  return [
    Query.resolve({
      ...request.payload,
      createKeychain: () => dispatch(createKeychainInitiated({ id: uuid(), adminId })),
    }),
    false,
  ];
};
