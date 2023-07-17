import { ApiErrorMessage, ListComputers, Loading } from '@dash/components';
import React from 'react';
import { Key, useQuery } from '../../hooks';
import Current from '../../environment';

const Computers: React.FC = () => {
  const query = useQuery(Key.devices, Current.api.getDevices);

  if (query.isLoading) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return <ListComputers devices={query.data} />;
};

export default Computers;
