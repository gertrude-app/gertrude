import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import CardContainer from '#/components/CardContainer';
import UnlockRequestCard from '#/components/UnlockRequestCard';
import { mockUnlockRequests } from '#/lib/mock-data';

export const UnlockRequestsPage: React.FC = () => (
  <CardContainer className="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2 @5xl/main:grid-cols-3">
    {mockUnlockRequests.map((request) => (
      <UnlockRequestCard key={request.id} request={request} />
    ))}
  </CardContainer>
);

export const Route = createFileRoute(`/_app/requests/unlock`)({
  component: UnlockRequestsPage,
});
