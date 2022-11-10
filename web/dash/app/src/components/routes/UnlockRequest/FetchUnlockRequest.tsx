import React from 'react';
import { Navigate, useNavigate, useParams } from 'react-router-dom';
import { Modal, UserInputText } from '@dash/components';
import { useUnlockRequestLoader } from '../loaders/unlock-request';

const FetchUnlockRequest: React.FC = () => {
  const navigate = useNavigate();
  const { unlockRequestId = `` } = useParams<{ unlockRequestId: string }>();
  const loader = useUnlockRequestLoader(unlockRequestId);
  if (loader.state === `unresolved`) {
    return loader.element;
  }

  const { entity: unlockRequest } = loader;
  if (unlockRequest.status === `pending`) {
    return <Navigate to={`./review`} />;
  }

  return (
    <Modal
      title="Unlock Request"
      primaryButton={() => navigate(`..`)}
      icon={unlockRequest.status === `rejected` ? `thumbs-down` : `thumbs-up`}
    >
      <div className="mt-4">
        <span className="text-base pr-1">The unlock request has been</span>
        <UserInputText small>{unlockRequest.status}</UserInputText>.
      </div>
    </Modal>
  );
};

export default FetchUnlockRequest;
