import { EmptyState } from '@gertrude/ui';
import { ClockIcon, MusicIcon } from 'lucide-react';
import React from 'react';
import type { IosMusicSettings } from '#/components/pages/person-settings/IosSettingsPage.types';
import type { PersonSettingsPreviewChip } from './PersonSettingsExpandableSection';
import PersonSettingsExpandableSection from './PersonSettingsExpandableSection';

interface Props {
  music: IosMusicSettings;
  defaultExpanded?: boolean;
}

const MusicSection: React.FC<Props> = ({ music, defaultExpanded }) => {
  const previewChips: PersonSettingsPreviewChip[] = [
    {
      title: `Status`,
      values: [
        music.requiresPayment
          ? { text: `Unavailable`, color: `neutral` }
          : { text: `Connected`, color: `violet` },
      ],
    },
  ];

  return (
    <PersonSettingsExpandableSection
      appIconUrl="/gertrude-app-icons/music.webp"
      title="Gertrude Music"
      defaultExpanded={defaultExpanded}
      previewChips={previewChips}
    >
      {music.requiresPayment ? (
        <EmptyState
          icon={MusicIcon}
          title="Gertrude Music isn’t available for this account"
          description="This device is connected, but Gertrude Music isn’t available for this account."
          className="bg-white"
        />
      ) : (
        <EmptyState
          icon={ClockIcon}
          title="Album approvals are coming soon"
          description="Approving albums for Gertrude Music isn’t available on the new site yet. For now, you can manage them from your existing Gertrude dashboard."
          className="bg-white"
        />
      )}
    </PersonSettingsExpandableSection>
  );
};

export default MusicSection;
