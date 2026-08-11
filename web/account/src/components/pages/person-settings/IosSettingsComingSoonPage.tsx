import { EmptyState } from '@gertrude/ui';
import { MonitorSmartphoneIcon } from 'lucide-react';
import React from 'react';
import CardContainer from '#/components/layout/CardContainer';

const IosSettingsComingSoonPage: React.FC = () => (
  <CardContainer>
    <EmptyState
      icon={MonitorSmartphoneIcon}
      title="iPhone and iPad settings are coming soon"
      description="You'll be able to manage Gertrude apps and device protections here."
      className="bg-white"
    />
  </CardContainer>
);

export default IosSettingsComingSoonPage;
