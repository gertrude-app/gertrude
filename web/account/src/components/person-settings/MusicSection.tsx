import { Badge, EmptyState, HStack, Text, VStack } from '@gertrude/ui';
import { formatDate } from '@shared/datetime';
import { ClockIcon, MusicIcon } from 'lucide-react';
import React from 'react';
import type { IosMusicSettings } from '#/components/pages/person-settings/IosSettingsPage.types';
import type { Device } from '#/components/types';
import type { PersonSettingsPreviewChip } from './PersonSettingsExpandableSection';
import PersonSettingsExpandableSection from './PersonSettingsExpandableSection';
import DeviceArtwork from '#/components/people/DeviceArtwork';
import { deviceSubtitle, deviceTitle } from '#/components/utils';

type IOSDevice = Extract<Device, { type: `iphone` | `ipad` }>;

export interface MusicDeviceConnection {
  device: IOSDevice;
  music: IosMusicSettings;
}

interface Props {
  connections: MusicDeviceConnection[];
  defaultExpanded?: boolean;
}

const connectionStatus = (
  music: IosMusicSettings,
): { label: string; color: `violet` | `neutral`; detail?: string } => {
  switch (music.subscription.case) {
    case `active`:
      return { label: `Connected`, color: `violet` };
    case `trial`:
      return {
        label: `Free trial`,
        color: `violet`,
        detail: `Ends ${formatDate(new Date(music.subscription.expiresAt), `long`)}`,
      };
    case `unavailable`:
      return { label: `Unavailable`, color: `neutral` };
  }
};

const MusicSection: React.FC<Props> = ({ connections, defaultExpanded }) => {
  const hasActiveConnection = connections.some(
    ({ music }) => music.subscription.case === `active`,
  );
  const hasTrialConnection = connections.some(
    ({ music }) => music.subscription.case === `trial`,
  );
  const hasAvailableConnection = hasActiveConnection || hasTrialConnection;
  const status = hasActiveConnection
    ? `Connected`
    : hasTrialConnection
      ? `Free trial`
      : `Unavailable`;
  const previewChips: PersonSettingsPreviewChip[] = [
    {
      title: `Status`,
      values: [{ text: status, color: hasAvailableConnection ? `violet` : `neutral` }],
    },
    {
      title: `Devices`,
      values: [
        {
          text: `${connections.length} connected`,
          color: `violet`,
        },
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
      <VStack gap={4}>
        <VStack gap={2}>
          <Text variant="bodyStrong">Connected devices</Text>
          <div className="flex flex-wrap gap-2">
            {connections.map(({ device, music }) => {
              const connection = connectionStatus(music);
              return (
                <HStack
                  key={device.id}
                  align="center"
                  justify="between"
                  gap={3}
                  className="min-w-60 flex-1 rounded-xl border border-stone-200 bg-stone-50 px-3 py-3"
                >
                  <HStack align="center" gap={2} className="min-w-0">
                    <DeviceArtwork device={device} size="medium" />
                    <VStack gap={0} className="min-w-0">
                      <Text variant="bodyStrong" truncate>
                        {deviceTitle(device)}
                      </Text>
                      <Text variant="captionMuted" truncate>
                        {deviceSubtitle(device)}
                      </Text>
                    </VStack>
                  </HStack>
                  <VStack gap={1.5} align="end">
                    <Badge size="small" color={connection.color}>
                      {connection.label}
                    </Badge>
                    {connection.detail && (
                      <Text variant="captionMuted" className="text-[10px] leading-3">
                        {connection.detail}
                      </Text>
                    )}
                  </VStack>
                </HStack>
              );
            })}
          </div>
        </VStack>
        {hasAvailableConnection ? (
          <EmptyState
            icon={ClockIcon}
            title="Album approvals are coming soon"
            description="Approving albums for Gertrude Music isn’t available on the new site yet. For now, you can manage them from your existing Gertrude dashboard."
            className="bg-white"
          />
        ) : (
          <EmptyState
            icon={MusicIcon}
            title="Gertrude Music isn’t available for this account"
            description="Music is connected, but it isn’t currently available for this account."
            className="bg-white"
          />
        )}
      </VStack>
    </PersonSettingsExpandableSection>
  );
};

export default MusicSection;
