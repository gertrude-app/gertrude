import { HStack, Text, VStack } from '@gertrude/ui';
import React from 'react';
import type { IOSDevice } from '#/components/types';
import DeviceArtwork from '#/components/people/DeviceArtwork';
import { deviceSubtitle, deviceTitle } from '#/components/utils';

interface Props {
  device: IOSDevice;
  children: React.ReactNode;
}

const IosDeviceSettingsSection: React.FC<Props> = ({ device, children }) => (
  <VStack
    as="section"
    id={device.id}
    gap={3}
    className="scroll-mt-6 rounded-2xl outline-none target:ring-2 target:ring-violet-300/70 target:ring-offset-4 target:ring-offset-white"
  >
    <HStack gap={2} align="center" className="-ml-1 @xl/main:ml-0 @xl/main:px-2">
      <div className="shrink-0 translate-x-px">
        <DeviceArtwork device={device} size="medium" />
      </div>
      <VStack gap={0} className="min-w-0">
        <Text as="h3" variant="bodyLargeStrong" truncate className="leading-5">
          {deviceTitle(device)}
        </Text>
        <Text variant="captionMuted" truncate className="leading-4">
          {deviceSubtitle(device)}
        </Text>
      </VStack>
    </HStack>
    {children}
  </VStack>
);

export default IosDeviceSettingsSection;
