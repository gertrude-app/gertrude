import { ApiErrorMessage, ListComputers, Loading } from '@dash/components';
import React from 'react';
import Current from '../../environment';
import { Key, useQuery } from '../../hooks';

const Computers: React.FC = () => {
  const query = useQuery(Key.computers, Current.api.getDevices);

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return <ListComputers devices={query.data} />;
};

export default Computers;
