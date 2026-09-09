import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import UnlockRequestsPage, {
  type UnlockRequestSummaryState,
} from '#/components/pages/requests/UnlockRequestsPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

const UnlockRequestsRoute: React.FC = () => {
  const unlockRequests = useQuery(
    Key.unlockRequests,
    () => liveClient.getAccountUnlockRequestSummary(),
    { refetchInterval: 30_000 },
  );
  const suspensionRequests = useQuery(Key.suspensionRequests, () =>
    liveClient.getSuspensionRequests(),
  );

  const state: UnlockRequestSummaryState =
    unlockRequests.data !== undefined
      ? { status: `success`, data: unlockRequests.data }
      : unlockRequests.isError
        ? {
            status: `error`,
            message:
              unlockRequests.error.userMessage ?? `Check your connection and try again.`,
            onRetry: () => void unlockRequests.refetch(),
          }
        : { status: `loading` };

  return (
    <UnlockRequestsPage
      state={state}
      suspensionRequestCount={suspensionRequests.data?.length}
      refreshing={unlockRequests.isFetching}
      onRefresh={() => void unlockRequests.refetch()}
      reviewHrefForPerson={(personId) => `/requests/unlock/${personId}`}
    />
  );
};

export const Route = createFileRoute(`/_app/requests/unlock/`)({
  component: UnlockRequestsRoute,
});
