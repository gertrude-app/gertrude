import { Button, HStack, Text, VStack } from '@gertrude/ui';
import { KeyIcon } from 'lucide-react';
import React from 'react';
import type { IosPodcastsSubscription } from '#/components/pages/person-settings/IosSettingsPage.types';
import type { PersonSettingsPreviewChip } from './PersonSettingsExpandableSection';
import type { PodcastsRunway, PodcastsRunwayTier } from './podcastsSubscriptionRunway';
import PersonSettingsExpandableSection from './PersonSettingsExpandableSection';
import PodcastsPinResetModal from './PodcastsPinResetModal';
import SettingsRow from './SettingsRow';
import { podcastsSubscriptionRunway } from './podcastsSubscriptionRunway';

interface Props {
  subscription: IosPodcastsSubscription;
  deviceName: string;
  requestingPinReset?: boolean;
  onRequestPinReset: () => Promise<number | null>;
  defaultExpanded?: boolean;
}

const CHIP_TEXT: Record<PodcastsRunwayTier, string> = {
  active: `Active`,
  expiring: `Ending soon`,
  lapsed: `Paused`,
};

function statusLine({ tier, accessEndsAt, trialDaysRemaining }: PodcastsRunway): string {
  if (tier === `lapsed`) {
    return `Paused — your Gertrude account needs Light or higher.`;
  }
  if (tier === `expiring`) {
    return `Active — access ends ${accessEndsAt}.`;
  }
  if (trialDaysRemaining !== undefined) {
    return `Active — free trial, ${trialDaysRemaining} days remaining.`;
  }
  return `Active.`;
}

const PodcastsSection: React.FC<Props> = ({
  subscription,
  deviceName,
  requestingPinReset = false,
  onRequestPinReset,
  defaultExpanded,
}) => {
  const [code, setCode] = React.useState<number | null>(null);
  const [modalOpen, setModalOpen] = React.useState(false);
  const runway = podcastsSubscriptionRunway(subscription);

  const handleResetPin = (): void => {
    void onRequestPinReset().then((result) => {
      if (result !== null) {
        setCode(result);
        setModalOpen(true);
      }
    });
  };

  const previewChips: PersonSettingsPreviewChip[] = [
    {
      title: `Status`,
      values: [
        {
          text: CHIP_TEXT[runway.tier],
          color: runway.tier === `active` ? `violet` : `neutral`,
        },
      ],
    },
  ];

  return (
    <>
      <PersonSettingsExpandableSection
        appIconUrl="/gertrude-app-icons/podcasts.webp"
        title="Gertrude Podcasts"
        defaultExpanded={defaultExpanded}
        previewChips={previewChips}
      >
        <VStack gap={3}>
          <Text variant="bodyMuted">{statusLine(runway)}</Text>
          <SettingsRow
            type="alwaysOn"
            title="Reset PIN"
            description="Generate a one-time code to clear the Gertrude Podcasts PIN on this device."
          >
            <HStack justify="end">
              <Button
                type="button"
                icon={KeyIcon}
                loading={requestingPinReset}
                disabled={requestingPinReset}
                onClick={handleResetPin}
                className="w-full @lg/main:w-auto"
              >
                Reset PIN
              </Button>
            </HStack>
          </SettingsRow>
        </VStack>
      </PersonSettingsExpandableSection>
      <PodcastsPinResetModal
        open={modalOpen}
        onOpenChange={setModalOpen}
        deviceName={deviceName}
        code={code}
      />
    </>
  );
};

export default PodcastsSection;
