import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import UnlockRequestsPage from '#/components/pages/requests/UnlockRequestsPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

const UnlockRequestsRoute: React.FC = () => {
  const suspensionRequests = useQuery(Key.suspensionRequests, () =>
    liveClient.getSuspensionRequests(),
  );

  return <UnlockRequestsPage suspensionRequestCount={suspensionRequests.data?.length} />;
};

export const Route = createFileRoute(`/_app/requests/unlock`)({
  component: UnlockRequestsRoute,
});
