import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import CardContainer from '#/components/CardContainer';
import SuspensionRequestCard from '#/components/SuspensionRequestCard';
import { getSuspensionRequestsPage, useMockData } from '#/lib/mock';

const SuspensionRequestsPage: React.FC = () => {
  const { db, dispatch } = useMockData();
  const { requests } = getSuspensionRequestsPage(db);
  const resolveRequest = (id: string): void => {
    dispatch({ type: `suspensionRequest.resolve`, id });
  };

  return (
    <CardContainer className="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2 @5xl/main:grid-cols-3">
      {requests.map((request) => (
        <SuspensionRequestCard
          key={request.id}
          request={request}
          onDeny={resolveRequest}
          onGrant={resolveRequest}
        />
      ))}
    </CardContainer>
  );
};

export const Route = createFileRoute(`/_app/requests/suspension`)({
  component: SuspensionRequestsPage,
});
