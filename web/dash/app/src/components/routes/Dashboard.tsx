import { Loading, ApiErrorMessage } from '@dash/components';
import React from 'react';
import { Dashboard } from '@dash/components';
import Current from '../../environment';
import { useQuery, Key } from '../../hooks';

const DashboardRoute: React.FC = () => {
  const query = useQuery(Key.dashboard, Current.api.getDashboardWidgets);

  if (query.isLoading) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return <Dashboard {...query.data} />;
};

export default DashboardRoute;
