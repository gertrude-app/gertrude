import React from 'react';
import type { UnlockRequest, UnlockRequestKeyDraft } from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import UnlockRequestCard from '#/components/requests/UnlockRequestCard';

interface Props {
  requests: UnlockRequest[];
  keychainOptions: Array<{ id: string; name: string }>;
  onDeny: (id: string, reason: string) => void;
  onAllow: (id: string, keys: UnlockRequestKeyDraft[]) => void;
}

const UnlockRequestsPage: React.FC<Props> = ({
  requests,
  keychainOptions,
  onDeny,
  onAllow,
}) => (
  <CardContainer className="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2 @5xl/main:grid-cols-3">
    {requests.map((request) => (
      <UnlockRequestCard
        key={request.id}
        request={request}
        keychainOptions={keychainOptions}
        onDeny={onDeny}
        onAllow={onAllow}
      />
    ))}
  </CardContainer>
);

export default UnlockRequestsPage;
