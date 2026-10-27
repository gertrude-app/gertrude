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
  action?: React.ReactNode;
}

const DeviceListRow: React.FC<Props> = ({ device, href, action }) => {
  const card = (
    <Card
      padding={3}
      className={cx(
        `flex flex-wrap items-center justify-between gap-3`,
        href && `group-hover:border-stone-300`,
      )}
    >
      <HStack className="min-w-0" gap={3}>
        <DeviceArtwork device={device} size="large" />
        <VStack className="min-w-0">
          <HStack gap={2} className="min-w-0">
            <Text variant="bodyLargeStrong" truncate>
              {deviceTitle(device)}
            </Text>
            {device.type === `mac` && (
              <Badge size="xsmall" color={device.online ? `green` : `neutral`}>
                {device.online ? `Online` : `Offline`}
              </Badge>
            )}
          </HStack>
          <Text variant="bodyMuted" truncate>
            {deviceSubtitle(device)}
          </Text>
        </VStack>
      </HStack>
      <VStack
        align="end"
        justify="between"
        gap={2}
        className={cx(
          `ml-auto min-w-0 max-w-full`,
          device.type === `mac` && `self-stretch`,
        )}
      >
        <HStack gap={2}>
          {device.type === `mac` ? (
            <Text
              variant="captionMuted"
              truncate
              className={cx(`max-w-44`, action && `mr-2.25`)}
            >
              Mac user:{` `}
              <Text variant="captionStrong">{device.username}</Text>
            </Text>
          ) : (
            <Badge size="small" color="neutral">
              {device.type === `iphone` ? `iPhone` : `iPad`}
            </Badge>
          )}
          {href && (
            <ChevronRightIcon className="w-5 h-5 text-stone-400 shrink-0 group-hover:text-stone-600" />
          )}
        </HStack>
        {action && <div className="shrink-0">{action}</div>}
      </VStack>
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
