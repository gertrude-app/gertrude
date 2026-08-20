import { ApiErrorMessage, ListDevices, Loading } from '@dash/components';
import React from 'react';
import Current from '../../environment';
import { Key, useComputerStatuses, useQuery } from '../../hooks';

const Computers: React.FC = () => {
  const query = useQuery(Key.allDevices, Current.api.getAllDevices);
  const statusesQuery = useComputerStatuses();

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const computers = query.data.computers.map((computer) => ({
    ...computer,
    users: computer.users.map((user) => ({
      ...user,
      status:
        statusesQuery.data?.find(
          (status) => status.computerUserId === user.computerUserId,
        )?.status ?? user.status,
    })),
  }));

  return <ListDevices computers={computers} iosDevices={query.data.iosDevices} />;
};

export default Computers;
