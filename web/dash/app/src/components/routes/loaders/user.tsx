import React, { useEffect } from 'react';
import { ErrorModal, LoadingModal } from '@dash/components';
import type { User } from '@dash/types';
import type { EntityLoader } from './loader-types';
import { useDispatch, useSelector } from '../../../redux/hooks';
import UnexpectedError from '../../UnexpectedError';
import { fetchUser } from '../../../redux/slice-users';

export function useUserLoader(id: UUID): EntityLoader<Editable<User>> {
  const dispatch = useDispatch();
  const { userReq, user } = useSelector((state) => ({
    userReq: state.users.fetchUserRequest[id],
    user: state.users.entities[id],
  }));

  useEffect(() => {
    if (!user?.original.id && (!userReq?.state || userReq.state === `idle`)) {
      dispatch(fetchUser(id));
    }
  }, [id, dispatch, userReq?.state, user?.original.id]);

  if (user) {
    return {
      state: `resolved`,
      entity: user,
    };
  }

  if (!userReq || userReq.state === `idle` || userReq.state === `ongoing`) {
    return { state: `unresolved`, element: <LoadingModal /> };
  }

  if (userReq.state === `failed`) {
    return {
      state: `unresolved`,
      isError: true,
      element: <ErrorModal entity="User" error={userReq.error} />,
    };
  }

  // unreachable
  return {
    state: `unresolved`,
    element: <UnexpectedError id="daa166d6" />,
  };
}
