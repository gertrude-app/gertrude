import {
  ApiErrorMessage,
  BatchUnlockRequests,
  EmptyState,
  Loading,
} from '@dash/components';
import React from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import Current from '../../../environment';
import { Key, useMutation, useQuery } from '../../../hooks';

const UserUnlockRequests: React.FC = () => {
  const { userId: id = `` } = useParams<{ userId: string }>();
  const navigate = useNavigate();
  const query = useQuery(Key.batchUnlockRequestData(id), () =>
    Current.api.getBatchUnlockRequestData(id),
  );

  const hadUndecided = React.useRef(false);
  const submit = useMutation(Current.api.handleUnlockRequests, {
    invalidating: [Key.batchUnlockRequestData(id), Key.dashboard],
    onSuccess() {
      if (hadUndecided.current) {
        hadUndecided.current = false;
      } else {
        navigate(`/`);
      }
    },
  });

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const { requests, keychains } = query.data;

  if (requests.length === 0) {
    return (
      <EmptyState
        heading="No pending unlock requests"
        secondaryText="This child has no pending unlock requests to review."
        icon="unlock"
        buttonText="Back to child"
        buttonIcon="arrow-left"
        action={`/children/${id}`}
      />
    );
  }

  return (
    <BatchUnlockRequests
      childName={requests[0]?.userName ?? ``}
      requests={requests}
      keychains={keychains}
      onSubmit={(data, numUndecided) => {
        hadUndecided.current = numUndecided > 0;
        submit.mutate(data);
      }}
      submitting={submit.isPending}
    />
  );
};

export default UserUnlockRequests;
