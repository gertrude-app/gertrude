import { Outlet, createFileRoute } from '@tanstack/react-router';
import React from 'react';
import SuspensionRequestsPage, {
  type SuspensionRequestsState,
} from '#/components/pages/requests/SuspensionRequestsPage';
import { toSuspensionRequest } from '#/lib/suspensionRequests';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

const SuspensionRequestsRoute: React.FC = () => {
  const query = useQuery(Key.suspensionRequests, () =>
    liveClient.getSuspensionRequests(),
  );

  const state: SuspensionRequestsState =
    query.data !== undefined
      ? {
          status: `success`,
          data: query.data.map(toSuspensionRequest),
        }
      : query.isError
        ? {
            status: `error`,
            message: query.error.userMessage ?? `Check your connection and try again.`,
            onRetry: () => void query.refetch(),
          }
        : { status: `loading` };

  return (
    <>
      <SuspensionRequestsPage
        state={state}
        refreshing={query.isFetching}
        onRefresh={() => void query.refetch()}
        responseHrefForRequest={(id) => `/requests/suspension/${id}`}
      />
      <Outlet />
    </>
  );
};

export const Route = createFileRoute(`/_app/requests/suspension`)({
  component: SuspensionRequestsRoute,
});
