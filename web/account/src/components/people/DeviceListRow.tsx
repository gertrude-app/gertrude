import { Badge, Card, HStack, Text, VStack } from '@gertrude/ui';
import React from 'react';
import type { Device } from '#/components/types';
import DeviceArtwork from '#/components/people/DeviceArtwork';
import { deviceSubtitle, deviceTitle } from '#/components/utils';

interface Props {
  device: Device;
}

const DeviceListRow: React.FC<Props> = ({ device }) => (
  <Card padding={3} className="flex items-center justify-between gap-3 pr-6">
    <HStack className="min-w-0" gap={3}>
      <DeviceArtwork device={device} size="large" />
      <VStack className="min-w-0">
        <Text variant="bodyLargeStrong" truncate>
          {deviceTitle(device)}
        </Text>
        <Text variant="bodyMuted" truncate>
          {deviceSubtitle(device)}
        </Text>
      </VStack>
    </HStack>
    <Badge
      size="small"
      color={device.type === `mac` && device.online ? `green` : `neutral`}
    >
      {device.type === `mac`
        ? device.online
          ? `Online`
          : `Offline`
        : device.type === `iphone`
          ? `iPhone`
          : `iPad`}
    </Badge>
  </Card>
);

export default DeviceListRow;
