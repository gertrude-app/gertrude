import { EmptyState } from '@gertrude/ui';
import { KeyRoundIcon } from 'lucide-react';
import React from 'react';
import RequestsShellPage from './RequestsShellPage';
import CardContainer from '#/components/layout/CardContainer';

interface Props {
  suspensionRequestCount?: number;
}

const UnlockRequestsPage: React.FC<Props> = ({ suspensionRequestCount }) => (
  <RequestsShellPage selected="unlock" suspensionRequestCount={suspensionRequestCount}>
    <CardContainer>
      <EmptyState
        icon={KeyRoundIcon}
        title="Unlock requests are coming soon"
        description="You'll be able to review and respond to website unlock requests here."
        className="bg-white"
      />
    </CardContainer>
  </RequestsShellPage>
);

export default UnlockRequestsPage;
