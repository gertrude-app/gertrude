import { Banner, EmptyState, VStack } from '@gertrude/ui';
import { formatDate } from '@shared/datetime';
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
  const { subscription } = music;
  const previewChips: PersonSettingsPreviewChip[] = [
    {
      title: `Status`,
      values: [
        subscription.case === `unavailable`
          ? { text: `Unavailable`, color: `neutral` }
          : subscription.case === `trial`
            ? { text: `Free trial`, color: `violet` }
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
      {subscription.case === `unavailable` ? (
        <EmptyState
          icon={MusicIcon}
          title="Gertrude Music isn’t available for this account"
          description="This device is connected, but Gertrude Music isn’t available for this account."
          className="bg-white"
        />
      ) : (
        <VStack gap={3}>
          {subscription.case === `trial` && (
            <Banner>
              <strong>21 Day Free Trial Active.</strong> After{` `}
              {formatDate(new Date(subscription.expiresAt), `long`)}, Gertrude Music is
              {` `}
              <strong>$5/month for the whole family</strong>. You won’t be charged
              automatically.
            </Banner>
          )}
          <EmptyState
            icon={ClockIcon}
            title="Album approvals are coming soon"
            description="Approving albums for Gertrude Music isn’t available on the new site yet. For now, you can manage them from your existing Gertrude dashboard."
            className="bg-white"
          />
        </VStack>
      )}
    </PersonSettingsExpandableSection>
  );
};

export default MusicSection;
