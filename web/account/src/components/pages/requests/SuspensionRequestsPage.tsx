import React from 'react';
import type { SuspensionRequest } from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import SuspensionRequestCard from '#/components/requests/SuspensionRequestCard';

interface Props {
  requests: SuspensionRequest[];
  onDeny: (id: string, reason: string) => void;
  onGrant: (id: string, duration: string) => void;
}

const SuspensionRequestsPage: React.FC<Props> = ({ requests, onDeny, onGrant }) => (
  <CardContainer className="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2 @5xl/main:grid-cols-3">
    {requests.map((request) => (
      <SuspensionRequestCard
        key={request.id}
        request={request}
        onDeny={onDeny}
        onGrant={onGrant}
      />
    ))}
  </CardContainer>
);

export default SuspensionRequestsPage;
