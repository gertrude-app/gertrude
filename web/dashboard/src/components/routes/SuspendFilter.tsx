import React, { useEffect } from 'react';
import Modal from '@shared/dashboard/Modal';
import SuspendFilterRequestForm from '@dashboard/Users/SuspendFilterRequestForm';
import { RequestStatus } from '@shared/dashboard/types/GraphQL';
import UserInputText from '@shared/dashboard/Keychains/Keys/KeyCreator/UserInputText';
import { useDispatch, useSelector } from '../../redux/hooks';
import { useNavigate, useParams } from 'react-router-dom';
import ApiErrorMessage from '../ApiErrorMessage';
import {
  getSuspendFilterRequest,
  responseCommentUpdated,
  grantedDurationInSecondsUpdated,
  grantedCustomDurationInMinutesUpdated,
  updateSuspendFilterRequest,
} from '../../redux/slice-filter-suspensions';

const SuspendFilter: React.FC = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const goToDashboard: () => unknown = () => navigate(`/`);
  const { id = `` } = useParams<{ id: string }>();
  const {
    updateReq,
    fetchReq,
    responseComment,
    grantedDurationInSeconds,
    grantedCustomDurationInMinutes,
  } = useSelector((state) => ({
    updateReq: state.filterSuspensions.updateReqs[id],
    fetchReq: state.filterSuspensions.fetchReqs[id],
    responseComment: state.filterSuspensions.responseComment,
    grantedDurationInSeconds: state.filterSuspensions.grantedDurationInSeconds,
    grantedCustomDurationInMinutes:
      state.filterSuspensions.grantedCustomDurationInMinutes,
  }));
  const requestState = fetchReq?.state;

  useEffect(() => {
    if (!requestState) {
      dispatch(getSuspendFilterRequest(id));
    }
  }, [requestState, dispatch, id]);

  if (!fetchReq || fetchReq?.state === `ongoing` || fetchReq?.state === `idle`) {
    return (
      <Modal
        type="default"
        loading
        title=""
        isOpen={true}
        onPrimaryClick={() => {}}
        onSecondaryClick={() => {}}
      />
    );
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
        <ApiErrorMessage
          entity="Suspend filter Request"
          wrapped={false}
          error={fetchReq.error}
        />
      </Modal>
    );
  }

  const { payload } = fetchReq;
  if (payload.status === `accepted` || payload.status === `rejected`) {
    return (
      <Modal
        type="error"
        title="Suspend Filter Request"
        isOpen={true}
        onPrimaryClick={goToDashboard}
        onSecondaryClick={goToDashboard}
        icon={payload.status === `accepted` ? `thumbs-up` : `thumbs-down`}
      >
        <div className="mt-4">
          <span className="text-base pr-1">The filter suspension request has been</span>
          <UserInputText small>{payload.status}</UserInputText>.
        </div>
      </Modal>
    );
  }

  return (
    <Modal
      type="default"
      title="Suspend Filter Request"
      icon="stopwatch"
      isOpen
      primaryButtonText="Grant"
      secondaryButtonText="Deny"
      onPrimaryClick={() =>
        dispatch(updateSuspendFilterRequest({ id, status: RequestStatus.accepted }))
      }
      onSecondaryClick={() =>
        dispatch(updateSuspendFilterRequest({ id, status: RequestStatus.rejected }))
      }
      onDismiss={goToDashboard}
      primaryButtonDisabled={
        updateReq?.state === `ongoing` ||
        updateReq?.state === `succeeded` ||
        (grantedDurationInSeconds === `custom` &&
          (Number.isNaN(Number(grantedCustomDurationInMinutes)) ||
            Number(grantedCustomDurationInMinutes) <= 1))
      }
    >
      <SuspendFilterRequestForm
        username={payload.userName}
        requestedDurationInSeconds={payload.requestedDurationInSeconds}
        requestComment={payload.requestComment}
        durationInSeconds={grantedDurationInSeconds}
        customDurationInMinutes={grantedCustomDurationInMinutes}
        responseComment={responseComment}
        setResponseComment={(comment) => dispatch(responseCommentUpdated(comment))}
        setDuration={(duration) => dispatch(grantedDurationInSecondsUpdated(duration))}
        setCustomDuration={(custom) =>
          dispatch(grantedCustomDurationInMinutesUpdated(custom))
        }
      />
    </Modal>
  );
};

export default SuspendFilter;
