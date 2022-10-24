import React, { useEffect } from 'react';
import Modal from '@dashboard/Modal';
import UnlockRequestResponder from '@dashboard/UnlockRequestResponder';
import { toKeyRecord } from '@dashboard/lib/keys/convert';
import Loading from '@dashboard/Modal/Loading';
import UserInputText from '@dashboard/Keychains/Keys/KeyCreator/UserInputText';
import { useDispatch, useSelector } from '../../redux/hooks';
import { useNavigate, useParams } from 'react-router-dom';
import { editKeyEventReceived } from '../../redux/slice-keychains';
import ApiErrorMessage from '../ApiErrorMessage';
import { Req } from '../../redux/helpers';
import useApps from '../../hooks/apps';
import useSelectableKeychains from '../../hooks/selectable-keychains';
import {
  acceptUnlockRequestClicked,
  detailsExpandedToggled,
  getUnlockRequest,
  selectKeychainClicked,
  rejectUnlockRequest,
  acceptUnlockRequest,
} from '../../redux/slice-unlock-requests';

const UnlockRequest: React.FC = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const goToDashboard: () => unknown = () => navigate(`/`);
  const { id = `` } = useParams<{ id: string }>();
  const { fetchReq, detailsExpanded, editingKey, updateReq } = useSelector((state) => ({
    editingKey: state.keychains.editingKey,
    detailsExpanded: state.unlockRequests.detailsExpanded,
    fetchReq: state.unlockRequests.fetchReqs[id],
    updateReq: state.unlockRequests.updateReqs[id],
  }));

  const unlockRequest = Req.payload(fetchReq);
  const appsReq = useApps(unlockRequest?.state === `editingKey`);
  const keychainsReq = useSelectableKeychains(unlockRequest?.state === `editingKey`);

  useEffect(() => {
    !fetchReq?.state && dispatch(getUnlockRequest(id));
  }, [fetchReq?.state, dispatch, id]);

  if (
    !fetchReq ||
    fetchReq?.state === `ongoing` ||
    fetchReq?.state === `idle` ||
    unlockRequest?.state === `pendingUpdate` ||
    updateReq?.state === `ongoing` ||
    updateReq?.state === `idle`
  ) {
    return <Loading />;
  }

  if (fetchReq.state === `failed`) {
    return (
      <Modal
        type="error"
        title={fetchReq.error?.type === `not_found` ? `Not found` : `Error`}
        isOpen={true}
        onPrimaryClick={goToDashboard}
        onSecondaryClick={goToDashboard}
        icon={fetchReq.error?.type === `not_found` ? `question` : void 0}
      >
        <ApiErrorMessage entity="Unlock request" wrapped={false} error={fetchReq.error} />
      </Modal>
    );
  }

  if (updateReq?.state === `failed`) {
    return (
      <Modal
        type="error"
        title={updateReq.error?.type === `not_found` ? `Not found` : `Error`}
        isOpen={true}
        onPrimaryClick={goToDashboard}
        onSecondaryClick={goToDashboard}
      >
        <ApiErrorMessage wrapped={false} error={updateReq.error} />
      </Modal>
    );
  }

  if (!unlockRequest || (unlockRequest.state === `editingKey` && !editingKey)) {
    // should be unreachable, todo: maybe log/slack/honeycomb some kind of error
    return null;
  }

  if (unlockRequest.state === `decided`) {
    return (
      <Modal
        type="error"
        title="Unlock Request"
        isOpen={true}
        onPrimaryClick={goToDashboard}
        onSecondaryClick={goToDashboard}
        icon={unlockRequest.status === `rejected` ? `thumbs-down` : `thumbs-up`}
      >
        <div className="mt-4">
          <span className="text-base pr-1">The unlock request has been</span>
          <UserInputText small>{unlockRequest.status}</UserInputText>.
        </div>
      </Modal>
    );
  }

  const keychains = Req.payload(keychainsReq)?.own ?? [];

  return (
    <Modal
      type="container"
      icon="unlock"
      maximizeWidthForSmallScreens={unlockRequest.state === `editingKey`}
      title={(() => {
        switch (unlockRequest.state) {
          case `reviewing`:
            return `Unlock Request`;
          case `editingKey`:
            return `Review/edit unlocking key`;
          case `selectingKeychain`:
            return `Select keychain`;
        }
      })()}
      isOpen={true}
      primaryButtonText={(() => {
        switch (unlockRequest.state) {
          case `reviewing`:
            return <>Accept &rarr;</>;
          case `editingKey`:
            return <>Select keychain &rarr;</>;
          case `selectingKeychain`:
            return <>Submit &rarr;</>;
        }
      })()}
      secondaryButtonText={unlockRequest.state === `reviewing` ? `Deny` : `Cancel`}
      onDismiss={goToDashboard}
      primaryButtonDisabled={
        (unlockRequest.state === `editingKey` && toKeyRecord(editingKey) === null) ||
        (unlockRequest.state === `selectingKeychain` &&
          !keychains.some((kc) => kc.id === editingKey?.keychainId))
      }
      onPrimaryClick={() => {
        switch (unlockRequest.state) {
          case `reviewing`:
            dispatch(acceptUnlockRequestClicked(unlockRequest));
            break;
          case `editingKey`:
            dispatch(selectKeychainClicked(id));
            break;
          case `selectingKeychain`:
            dispatch(acceptUnlockRequest(id));
            break;
        }
      }}
      onSecondaryClick={() => {
        switch (unlockRequest.state) {
          case `reviewing`:
            dispatch(rejectUnlockRequest(id));
            break;
          case `editingKey`:
            goToDashboard();
            break;
          case `selectingKeychain`:
            goToDashboard();
            break;
        }
      }}
    >
      <UnlockRequestResponder
        updateKey={(event) => dispatch(editKeyEventReceived(event))}
        step={unlockRequest.state}
        detailsExpanded={detailsExpanded}
        setDetailsExpanded={() => dispatch(detailsExpandedToggled())}
        editingKey={editingKey}
        apps={Req.payload(appsReq) ?? []}
        selectableKeychains={keychains}
        {...unlockRequest}
      />
    </Modal>
  );
};

export default UnlockRequest;
