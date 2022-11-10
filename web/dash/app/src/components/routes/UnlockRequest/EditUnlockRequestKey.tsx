import React from 'react';
import { ErrorModal, KeyCreator, LoadingModal, Modal } from '@dash/components';
import { Navigate, useNavigate, useParams } from 'react-router-dom';
import { toKeyRecord } from '@dash/keys';
import { useDispatch, useSelector } from '../../../redux/hooks';
import useApps from '../../../hooks/apps';
import { editKeyEventReceived } from '../../../redux/slice-keychains';
import UnexpectedError from '../../UnexpectedError';
import { acceptUnlockRequest } from '../../../redux/slice-unlock-requests';

const EditUnlockRequestKey: React.FC = () => {
  const { unlockRequestId = `` } = useParams<{ unlockRequestId: string }>();
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const appsReq = useApps();
  const { key, updateReq } = useSelector((state) => ({
    key: state.keychains.editingKey,
    updateReq: state.unlockRequests.updateReqs[unlockRequestId],
  }));

  if (!key) {
    return <Navigate to="../select-keychain" />;
  }

  if (
    appsReq.state === `ongoing` ||
    appsReq.state === `idle` ||
    updateReq?.state === `ongoing`
  ) {
    return <LoadingModal />;
  }

  if (appsReq.state === `failed`) {
    return <UnexpectedError id="d9fedb07" />;
  }

  if (updateReq?.state === `failed`) {
    return (
      <ErrorModal
        title="Error accepting unlock request"
        error={updateReq.error}
        primaryButton={{ label: `Try again`, action: () => navigate(`..`) }}
      />
    );
  }

  if (updateReq?.state === `succeeded`) {
    return <Navigate to=".." />;
  }

  return (
    <Modal
      icon="key"
      type="container"
      title="Review/edit unlocking key"
      onDismiss={() => navigate(`../..`)}
      secondaryButton={{
        label: <>&larr; Back</>,
        action: () => navigate(`../select-keychain`),
      }}
      primaryButton={{
        label: <>Submit &rarr;</>,
        action: () => dispatch(acceptUnlockRequest(unlockRequestId)),
        disabled: toKeyRecord(key) === null,
      }}
    >
      <div className="px-2">
        <KeyCreator
          {...key}
          update={(event) => dispatch(editKeyEventReceived(event))}
          apps={appsReq.payload}
        />
      </div>
    </Modal>
  );
};

export default EditUnlockRequestKey;
