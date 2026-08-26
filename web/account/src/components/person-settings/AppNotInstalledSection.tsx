import { EmptyState } from '@gertrude/ui';
import { ExternalLinkIcon } from 'lucide-react';
import React from 'react';
import type { LucideIcon } from 'lucide-react';
import PersonSettingsExpandableSection from './PersonSettingsExpandableSection';

interface Props {
  appIconUrl: string;
  appName: string;
  icon: LucideIcon;
  description: string;
  appStoreUrl: string;
}

const AppNotInstalledSection: React.FC<Props> = ({
  appIconUrl,
  appName,
  icon,
  description,
  appStoreUrl,
}) => (
  <PersonSettingsExpandableSection
    appIconUrl={appIconUrl}
    title={appName}
    previewChips={[
      { title: `Status`, values: [{ text: `Not installed`, color: `neutral` }] },
    ]}
  >
    <EmptyState
      icon={icon}
      title={`${appName} isn’t on this device`}
      description={description}
      button={{
        text: `View on the App Store`,
        type: `link`,
        href: appStoreUrl,
        target: `_blank`,
        rel: `noopener noreferrer`,
        icon: ExternalLinkIcon,
      }}
      className="bg-white"
    />
  </PersonSettingsExpandableSection>
);

export default AppNotInstalledSection;
