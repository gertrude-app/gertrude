import React, { useEffect } from 'react';
import { Loading, ListUnlockRequests, ApiErrorMessage } from '@dash/components';
import { typesafe } from '@shared/ts-utils';
import { useDispatch, useSelector } from '../../../redux/hooks';
import { getUsersUnlockRequests } from '../../../redux/slice-unlock-requests';

const UsersUnlockRequests: React.FC = () => {
  const dispatch = useDispatch();
  const fetch = useSelector((state) => state.unlockRequests.fetchAllReq);
  const requests = useSelector((state) =>
    typesafe.objectValues(state.unlockRequests.entities),
  );

  useEffect(() => {
    if (fetch?.state === undefined || fetch?.state === `idle`) {
      dispatch(getUsersUnlockRequests());
    }
  }, [dispatch, fetch?.state]);

  if (!fetch?.state || fetch?.state === `idle` || fetch?.state === `ongoing`) {
    return <Loading />;
  }

  if (fetch?.state === `failed`) {
    return <ApiErrorMessage error={fetch.error} />;
  }

  return (
    <ListUnlockRequests
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

export default UsersUnlockRequests;
