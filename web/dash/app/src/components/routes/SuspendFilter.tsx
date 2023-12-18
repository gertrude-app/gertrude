import React from 'react';
import { isOlderThan } from '@dash/datetime';
import {
  Modal,
  Loading,
  SuspendFilterRequestForm,
  UserInputText,
  ErrorModal,
} from '@dash/components';
import { useNavigate, useParams } from 'react-router-dom';
import reducer, {
  durationInSeconds,
  userInitialState,
  useUserObserver,
} from '../../reducers/suspend-filter-request-reducer';
import { useQuery, useMutation, useObservedReducer, Key } from '../../hooks';
import Current from '../../environment';

const SuspendFilter: React.FC = () => {
  const { userId = ``, id = `` } = useParams<{ userId: UUID; id: UUID }>();
  const navigate = useNavigate();
  const queryKey = Key.suspendFilterRequest(id);
  const goToDashboard: () => unknown = () => navigate(`/`);

  const [state, dispatch] = useObservedReducer(
    reducer,
    userInitialState(userId),
    useUserObserver(userId),
  );

  const query = useQuery(
    Key.suspendFilterRequest(id),
    () => Current.api.getSuspendFilterRequest(id),
    { onReceive: (request) => dispatch({ type: `receivedRequest`, request }) },
  );

  const update = useMutation(
    (status: 'accepted' | 'rejected') =>
      Current.api.decideFilterSuspensionRequest({
        id,
        decision:
          status === `rejected`
            ? { case: `rejected` }
            : {
                case: `accepted`,
                durationInSeconds: durationInSeconds(state),
                extraMonitoring: state.extraMonitoring,
              },
        responseComment: state.responseComment.trim() || undefined,
      }),
    { invalidating: [queryKey], toast: `update:suspend-filter-request` },
  );

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ErrorModal error={query.error} />;
  }

  const request = query.data;
  if (request.status === `accepted` || request.status === `rejected`) {
    return (
      <Modal
        title="Suspend Filter Request"
        primaryButton={goToDashboard}
        icon={request.status === `accepted` ? `thumbs-up` : `thumbs-down`}
      >
        <div className="mt-4">
          <span className="text-base pr-1">The filter suspension request has been</span>
          <UserInputText small>{request.status}</UserInputText>.
        </div>
      </Modal>
    );
  }

  if (isOlderThan(request.createdAt, { hours: 2 })) {
    return (
      <Modal title="Suspend Filter Request" primaryButton={goToDashboard} icon="clock">
        <span className="text-base">
          This filter suspension request is <b>more than 2 hours old.</b> Have the child
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
        action: () => update.mutate(`accepted`),
        disabled:
          update.isPending ||
          update.isSuccess ||
          (state.grantedDurationInSeconds === `custom` &&
            (Number.isNaN(Number(state.grantedCustomDurationInMinutes)) ||
              Number(state.grantedCustomDurationInMinutes) <= 1)),
      }}
      secondaryButton={{
        label: `Deny`,
        action: () => update.mutate(`rejected`),
      }}
      onDismiss={goToDashboard}
    >
      <SuspendFilterRequestForm
        username={request.userName}
        requestedDurationInSeconds={request.requestedDurationInSeconds}
        requestComment={request.requestComment}
        durationInSeconds={state.grantedDurationInSeconds}
        customDurationInMinutes={state.grantedCustomDurationInMinutes}
        requestedAt={request.createdAt}
        responseComment={state.responseComment}
        setResponseComment={(comment) => dispatch({ type: `updateComment`, comment })}
        setDuration={(duration) => dispatch({ type: `updateDuration`, duration })}
        setCustomDuration={(custom) => dispatch({ type: `updateCustomDuration`, custom })}
        extraMonitoringOptions={request.extraMonitoringOptions}
        selectedExtraMonitoringOption={state.extraMonitoring}
        setSelectedExtraMonitoringOption={(extraMonitoring) =>
          dispatch({ type: `updateExtraMonitoring`, extraMonitoring })
        }
      />
    </Modal>
  );
};

export default SuspendFilter;
