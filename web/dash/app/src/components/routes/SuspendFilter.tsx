import React, { useEffect } from 'react';
import { RequestStatus } from '@dash/types';
import { isOlderThan } from '@dash/datetime';
import {
  Modal,
  Loading,
  SuspendFilterRequestForm,
  UserInputText,
  ErrorModal,
} from '@dash/components';
import { useNavigate, useParams } from 'react-router-dom';
import { useDispatch, useSelector } from '../../redux/hooks';
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

  useEffect(() => {
    if (!fetchReq?.state) {
      dispatch(getSuspendFilterRequest(id));
    }
  }, [fetchReq?.state, dispatch, id]);

  if (!fetchReq || fetchReq?.state === `ongoing` || fetchReq?.state === `idle`) {
    return <Loading />;
  }

  if (fetchReq.state === `failed`) {
    return <ErrorModal entity="Suspend filter request" error={fetchReq.error} />;
  }

  const { payload } = fetchReq;
  if (payload.status === `accepted` || payload.status === `rejected`) {
    return (
      <Modal
        title="Suspend Filter Request"
        primaryButton={goToDashboard}
        icon={payload.status === `accepted` ? `thumbs-up` : `thumbs-down`}
      >
        <div className="mt-4">
          <span className="text-base pr-1">The filter suspension request has been</span>
          <UserInputText small>{payload.status}</UserInputText>.
        </div>
      </Modal>
    );
  }

  if (isOlderThan(payload.createdAt, { hours: 2 })) {
    return (
      <Modal title="Suspend Filter Request" primaryButton={goToDashboard} icon="clock">
        <span className="text-base">
          This filter suspension request is <b>more than 2 hours old.</b> Have the user
          request another one if they still need their filter suspended.
        </span>
      </Modal>
    );
  }

  return (
    <Modal
      type="container"
      title="Suspend Filter Request"
      icon="stopwatch"
      primaryButton={{
        label: `Grant`,
        action: () =>
          dispatch(updateSuspendFilterRequest({ id, status: RequestStatus.accepted })),
        disabled:
          updateReq?.state === `ongoing` ||
          updateReq?.state === `succeeded` ||
          (grantedDurationInSeconds === `custom` &&
            (Number.isNaN(Number(grantedCustomDurationInMinutes)) ||
              Number(grantedCustomDurationInMinutes) <= 1)),
      }}
      secondaryButton={{
        label: `Deny`,
        action: () =>
          dispatch(updateSuspendFilterRequest({ id, status: RequestStatus.rejected })),
      }}
      onDismiss={goToDashboard}
    >
      <SuspendFilterRequestForm
        username={payload.userName}
        requestedDurationInSeconds={payload.requestedDurationInSeconds}
        requestComment={payload.requestComment}
        durationInSeconds={grantedDurationInSeconds}
        customDurationInMinutes={grantedCustomDurationInMinutes}
        requestedAt={payload.createdAt}
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
