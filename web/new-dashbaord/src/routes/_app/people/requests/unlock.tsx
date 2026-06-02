import React from 'react';
import { createFileRoute } from '@tanstack/react-router';
import CardContainer from '#/components/CardContainer';
import UnlockRequestCard from '#/components/UnlockRequestCard';
import { mockUnlockRequests } from '#/lib/mock-data';

const UnlockRequestsPage: React.FC = () => (
  <CardContainer className="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2 @5xl/main:grid-cols-3">
    {mockUnlockRequests.map((request) => (
      <UnlockRequestCard
        key={`${request.personName}-${request.domains.join(',')}`}
        request={request}
      />
    ))}
  </CardContainer>
);

export const Route = createFileRoute('/_app/people/requests/unlock')({
  component: UnlockRequestsPage,
});
