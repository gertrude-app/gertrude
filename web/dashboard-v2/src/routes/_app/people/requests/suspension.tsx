import React from 'react';
import { createFileRoute } from '@tanstack/react-router';
import CardContainer from '#/components/CardContainer';
import SuspensionRequestCard from '#/components/SuspensionRequestCard';
import { mockSuspensionRequests } from '#/lib/mock-data';

const SuspensionRequestsPage: React.FC = () => (
  <CardContainer className="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2 @5xl/main:grid-cols-3">
    {mockSuspensionRequests.map((request) => (
      <SuspensionRequestCard
        key={`${request.personName}-${request.duration}-${request.reason ?? ''}`}
        request={request}
      />
    ))}
  </CardContainer>
);

export const Route = createFileRoute('/_app/people/requests/suspension')({
  component: SuspensionRequestsPage,
});
