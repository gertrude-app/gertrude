import React from 'react';
import { useParams } from 'react-router-dom';
import { Loading, ListUnlockRequests, ApiErrorMessage } from '@dash/components';
import Current from '../../../environment';
import { useQuery, useUser, Key, useZip } from '../../../hooks';

const UserUnlockRequests: React.FC = () => {
  const { userId: id = `` } = useParams<{ userId: string }>();
  const query = useZip(
    useQuery(Key.userUnlockRequests(id), () => Current.api.getUserUnlockRequests(id)),
    useUser(id),
  );

  if (query.isLoading) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const [requests, user] = query.data;
  return (
    <ListUnlockRequests
      userName={user.name}
      requests={requests.map((req) => ({
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

export default UserUnlockRequests;
