import React, { useEffect } from 'react';
import { useParams } from 'react-router-dom';
import ListUnlockRequests from '@dashboard/Users/ListUnlockRequests';
import Loading from '@shared/Loading';
import * as typesafe from '../../lib/typesafe';
import { useDispatch, useSelector } from '../../redux/hooks';
import { getUserUnlockRequests } from '../../redux/slice-unlock-requests';
import ApiErrorMessage from '../ApiErrorMessage';

const UserUnlockRequests: React.FC = () => {
  const { userId: id = `` } = useParams<{ userId: string }>();
  const dispatch = useDispatch();
  const fetch = useSelector((state) => state.unlockRequests.fetchReqs[id]);
  const requests = useSelector((state) =>
    typesafe
      .objectValues(state.unlockRequests.entities)
      .filter((req) => req.userId === id),
  );

  useEffect(() => {
    if (fetch?.state === undefined || fetch?.state === `idle`) {
      dispatch(getUserUnlockRequests(id));
    }
  }, [dispatch, id, fetch?.state]);

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
        userName: req.userName,
        status: req.status,
        comment: req.requestComment,
        createdAt: req.createdAt,
      }))}
    />
  );
};

export default UserUnlockRequests;
