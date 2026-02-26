import { ApiErrorMessage, ListDevices, Loading } from '@dash/components';
import React from 'react';
import Current from '../../environment';
import { Key, useQuery } from '../../hooks';

const Computers: React.FC = () => {
  const query = useQuery(Key.allDevices, Current.api.getAllDevices);

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return (
    <ListDevices computers={query.data.computers} iosDevices={query.data.iosDevices} />
  );
};

export default Computers;
