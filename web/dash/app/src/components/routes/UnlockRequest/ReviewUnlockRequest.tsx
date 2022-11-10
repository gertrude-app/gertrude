import React from 'react';
import { Navigate, useNavigate, useParams } from 'react-router-dom';
import { Modal, ReviewUnlockRequest } from '@dash/components';
import { useDispatch, useSelector } from '../../../redux/hooks';
import { detailsExpandedToggled } from '../../../redux/slice-unlock-requests';
import { useUnlockRequestLoader } from '../loaders/unlock-request';

const ReviewUnlockRequestRoute: React.FC = () => {
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { unlockRequestId: id = `` } = useParams<{ unlockRequestId: string }>();
  const detailsExpanded = useSelector((state) => state.unlockRequests.detailsExpanded);
  const loader = useUnlockRequestLoader(id);
  if (loader.state === `unresolved`) {
    return loader.element;
  }

  const { entity: unlockRequest } = loader;
  if (unlockRequest.status !== `pending`) {
    return <Navigate to=".." />;
  }

  return (
    <Modal
      type="container"
      icon="unlock"
      title="Unlock Request"
      onDismiss={() => navigate(`../..`)}
      primaryButton={{
        label: <>Accept &rarr;</>,
        action: () => navigate(`../select-keychain`),
      }}
      secondaryButton={{
        label: `Deny`,
        action: () => navigate(`../deny`),
      }}
    >
      <ReviewUnlockRequest
        detailsExpanded={detailsExpanded}
        setDetailsExpanded={() => dispatch(detailsExpandedToggled())}
        {...unlockRequest}
      />
    </Modal>
  );
};

export default ReviewUnlockRequestRoute;
