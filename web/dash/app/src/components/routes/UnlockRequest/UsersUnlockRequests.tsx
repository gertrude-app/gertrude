import { ApiErrorMessage, ListUnlockRequests, Loading } from '@dash/components';
import React from 'react';
import Current from '../../../environment';
import { Key, useQuery } from '../../../hooks';

const UsersUnlockRequests: React.FC = () => {
  const query = useQuery(Key.combinedUsersUnlockRequests, Current.api.getUnlockRequests);

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return (
    <ListUnlockRequests
      requests={query.data.map((req) => ({
        id: req.id,
        url: req.url ?? req.domain ?? req.ipAddress ?? ``,
        userId: req.userId,
        userName: req.userName,
        status: req.status,
        comment: req.requestComment,
        createdAt: req.createdAt,
      }))}
    />
  );
};

export default UsersUnlockRequests;
