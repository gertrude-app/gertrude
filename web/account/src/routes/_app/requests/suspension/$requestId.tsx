import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React from 'react';
import SuspensionRequestResponseModal from '#/components/requests/SuspensionRequestResponseModal';
import SuspensionRequestStatusModal from '#/components/requests/SuspensionRequestStatusModal';
import { toSuspensionRequest } from '#/lib/suspensionRequests';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

const compactDuration = (durationInSeconds: number): string => {
  const minutes = Math.round(durationInSeconds / 60);

  if (minutes < 60) {
    return `${minutes}m`;
  }

  const hours = Math.floor(minutes / 60);
  const remainingMinutes = minutes % 60;
  return remainingMinutes === 0 ? `${hours}h` : `${hours}h ${remainingMinutes}m`;
};

const SuspensionRequestResponseRoute: React.FC = () => {
  const { requestId } = Route.useParams();
  const navigate = useNavigate();
  const close = (): void => {
    void navigate({ to: `/requests/suspension`, replace: true });
  };
  const query = useQuery(Key.suspensionRequests, () =>
    liveClient.getSuspensionRequests(),
  );
  const decision = useMutation(liveClient.decideSuspensionRequest, {
    invalidating: [Key.suspensionRequests],
    toast: {
      loading: `Updating suspension request…`,
      success: ({ decision }) =>
        decision.case === `accepted`
          ? `${compactDuration(decision.durationInSeconds)} suspension request granted`
          : `Suspension request denied`,
      error: `Failed to update suspension request`,
    },
    onSuccess: close,
  });
  const requestData = query.data?.find(
    (request) => request.id.toLowerCase() === requestId.toLowerCase(),
  );
  const request = requestData ? toSuspensionRequest(requestData) : undefined;

  if (!request && query.isFetching) {
    return (
      <SuspensionRequestStatusModal
        title="Loading request"
        description="Getting the latest details before you respond."
        loading
        onClose={close}
      />
    );
  }

  if (!request && query.isError) {
    return (
      <SuspensionRequestStatusModal
        title="Couldn't load request"
        description={query.error.userMessage ?? `Check your connection and try again.`}
        onClose={close}
        onRetry={() => void query.refetch()}
      />
    );
  }

  if (!request) {
    return (
      <SuspensionRequestStatusModal
        title="Request no longer pending"
        description="This request may have already been answered or may be more than two hours old."
        onClose={close}
      />
    );
  }

  const responding =
    decision.isPending && decision.variables
      ? decision.variables.decision.case === `accepted`
        ? `grant`
        : `deny`
      : undefined;
  const handleDeny = async (comment: string): Promise<void> => {
    await decision.mutateAsync({
      id: request.id,
      decision: { case: `rejected` },
      responseComment: comment || undefined,
    });
  };
  const handleGrant = async (
    durationInSeconds: number,
    extraMonitoring: string | undefined,
    comment: string,
  ): Promise<void> => {
    await decision.mutateAsync({
      id: request.id,
      decision: {
        case: `accepted`,
        durationInSeconds,
        extraMonitoring,
      },
      responseComment: comment || undefined,
    });
  };

  return (
    <SuspensionRequestResponseModal
      key={request.id}
      request={request}
      open
      responding={responding}
      onOpenChange={(open) => {
        if (!open) close();
      }}
      onDeny={handleDeny}
      onGrant={handleGrant}
    />
  );
};

export const Route = createFileRoute(`/_app/requests/suspension/$requestId`)({
  component: SuspensionRequestResponseRoute,
});
