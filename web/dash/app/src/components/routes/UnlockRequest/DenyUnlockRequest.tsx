import { useEffect } from 'react';
import { ErrorModal, LoadingModal } from '@dash/components';
import { Navigate, useNavigate, useParams } from 'react-router-dom';
import React from 'react';
import { useDispatch, useSelector } from '../../../redux/hooks';
import { rejectUnlockRequest } from '../../../redux/slice-unlock-requests';

const DenyUnlockRequest: React.FC = () => {
  const { unlockRequestId = `` } = useParams<{ unlockRequestId: string }>();
  const request = useSelector((s) => s.unlockRequests.updateReqs[unlockRequestId]);
  const navigate = useNavigate();
  const dispatch = useDispatch();

  useEffect(() => {
    if (!request?.state) {
      dispatch(rejectUnlockRequest(unlockRequestId));
    }
  }, [request?.state, dispatch, unlockRequestId]);

  if (!request || request.state === `ongoing` || request.state === `idle`) {
    return <LoadingModal />;
  }

  if (request.state === `failed`) {
    return (
      <ErrorModal
        title="Error denying unlock request"
        error={request.error}
        primaryButton={{ label: `Try again`, action: () => navigate(`..`) }}
      />
    );
  }
  return <Navigate to=".." />;
};

export default DenyUnlockRequest;
