import { ErrorModal, LoadingModal, Modal, ReviewUnlockRequest } from '@dash/components';
import React, { useState } from 'react';
import { Navigate, useNavigate, useParams } from 'react-router-dom';
import {
  useApps,
  useSelectableKeychains,
  useUnlockRequest,
  useUser,
} from '../../../hooks';

const ReviewUnlockRequestRoute: React.FC = () => {
  const { id = ``, userId = `` } = useParams<{ id: UUID; userId: UUID }>();
  const [detailsExpanded, setDetailsExpanded] = useState(false);
  const navigate = useNavigate();
  const query = useUnlockRequest(id);

  // used by subsequent screens, prefetch to minimize spinners
  useApps();
  useUser(userId);
  useSelectableKeychains();

  if (query.isPending) {
    return <LoadingModal />;
  }

  if (query.isError) {
    return <ErrorModal error={query.error} />;
  }

  if (query.data.status !== `pending`) {
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
        setDetailsExpanded={() => setDetailsExpanded(!detailsExpanded)}
        {...query.data}
      />
    </Modal>
  );
};

export default ReviewUnlockRequestRoute;
