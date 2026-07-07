import { Badge, Card, HStack, Text, VStack } from '@gertrude/ui';
import React from 'react';
import type { Device } from '#/components/types';
import { deviceImageUrl, deviceSubtitle, deviceTitle } from '#/components/utils';

interface Props {
  device: Device;
  href: string;
}

const DeviceListRow: React.FC<Props> = ({ device, href }) => (
  <Card
    as="a"
    href={href}
    padding={3}
    className="flex items-center justify-between gap-3 pr-6 transition-[border-color,box-shadow] duration-100 hover:border-stone-300 hover:shadow-stone-300/70 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-violet-300/80"
  >
    <HStack className="min-w-0" gap={3}>
      <HStack justify="center" className="h-10 w-12 shrink-0 text-stone-700">
        <img
          src={deviceImageUrl(device.type, device.modelIdentifier)}
          alt=""
          className="h-9 w-11 object-contain drop-shadow-sm"
        />
      </HStack>
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
