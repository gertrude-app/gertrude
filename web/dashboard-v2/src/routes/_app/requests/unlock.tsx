import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React from 'react';
import CardContainer from '#/components/CardContainer';
import UnlockRequestCard from '#/components/UnlockRequestCard';
import { getUnlockRequestsPage, useMockData } from '#/lib/mock';

export const UnlockRequestsPage: React.FC = () => {
  const { db, dispatch } = useMockData();
  const navigate = useNavigate();
  const { requests } = getUnlockRequestsPage(db);
  const resolveRequest = (id: string): void => {
    void navigate({ to: `/requests/unlock` });
    dispatch({ type: `unlockRequest.resolve`, id });
  };

  return (
    <CardContainer className="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2 @5xl/main:grid-cols-3">
      {requests.map((request) => (
        <UnlockRequestCard
          key={request.id}
          request={request}
          onDeny={resolveRequest}
          onAllow={resolveRequest}
        />
      ))}
    </CardContainer>
  );
};

export const Route = createFileRoute(`/_app/requests/unlock`)({
  component: UnlockRequestsPage,
});
