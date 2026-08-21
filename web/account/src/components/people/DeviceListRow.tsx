import { Badge, Card, HStack, Text, VStack } from '@gertrude/ui';
import { Link } from '@tanstack/react-router';
import cx from 'clsx';
import { ChevronRightIcon } from 'lucide-react';
import React from 'react';
import type { Device } from '#/components/types';
import DeviceArtwork from '#/components/people/DeviceArtwork';
import { deviceSubtitle, deviceTitle } from '#/components/utils';

interface Props {
  device: Device;
  href?: string;
}

const DeviceListRow: React.FC<Props> = ({ device, href }) => {
  const card = (
    <Card
      padding={3}
      className={cx(
        `flex items-center justify-between gap-3`,
        href ? `pr-4 group-hover:border-stone-300` : `pr-6`,
      )}
    >
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
      <HStack gap={2}>
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
        {href && (
          <ChevronRightIcon className="w-5 h-5 text-stone-400 shrink-0 group-hover:text-stone-600" />
        )}
      </HStack>
    </Card>
  );

  return href ? (
    <Link to={href} className="group block">
      {card}
    </Link>
  ) : (
    card
  );
};

export default DeviceListRow;
