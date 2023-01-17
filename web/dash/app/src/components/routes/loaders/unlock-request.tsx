import React, { useEffect } from 'react';
import { ErrorModal, LoadingModal } from '@dash/components';
import type { UnlockRequest } from '@dash/types';
import type { EntityLoader } from './loader-types';
import { useDispatch, useSelector } from '../../../redux/hooks';
import { getUnlockRequest } from '../../../redux/slice-unlock-requests';
import UnexpectedError from '../../UnexpectedError';

export function useUnlockRequestLoader(id: UUID): EntityLoader<UnlockRequest> {
  const dispatch = useDispatch();

  const { fetchReq, unlockRequest } = useSelector((state) => ({
    unlockRequest: state.unlockRequests.entities[id],
    fetchReq: state.unlockRequests.fetchReqs[id],
  }));

  useEffect(() => {
    if (!unlockRequest?.id && !fetchReq?.state) {
      dispatch(getUnlockRequest(id));
    }
  }, [fetchReq?.state, dispatch, unlockRequest?.id, id]);

  if (unlockRequest) {
    return { state: `resolved`, entity: unlockRequest };
  }

  if (!fetchReq || fetchReq?.state === `ongoing` || fetchReq?.state === `idle`) {
    return {
      state: `unresolved`,
      element: <LoadingModal />,
    };
  }

  if (fetchReq.state === `failed`) {
    return {
      state: `unresolved`,
      isError: true,
      element: <ErrorModal error={fetchReq.error} />,
    };
  }

  // unreachable: fetchReq is successful here, so we MUST have an unlock request
  return {
    state: `unresolved`,
    element: <UnexpectedError id="9c61e7fe" />,
  };
}
