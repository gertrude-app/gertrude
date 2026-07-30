import { EmptyState } from '@gertrude/ui';
import { LaptopIcon, MonitorSmartphoneIcon } from 'lucide-react';
import React from 'react';
import CardContainer from '#/components/layout/CardContainer';

interface Props {
  platform: `mac` | `ios`;
}

const PersonSettingsComingSoonPage: React.FC<Props> = ({ platform }) => {
  const isMac = platform === `mac`;

  return (
    <CardContainer>
      <EmptyState
        icon={isMac ? LaptopIcon : MonitorSmartphoneIcon}
        title={
          isMac
            ? `Mac settings are coming soon`
            : `iPhone and iPad settings are coming soon`
        }
        description={
          isMac
            ? `You'll be able to configure monitoring, filtering, downtime, and app access here.`
            : `You'll be able to manage Gertrude apps and device protections here.`
        }
        className="bg-white"
      />
    </CardContainer>
  );
};

export default PersonSettingsComingSoonPage;
