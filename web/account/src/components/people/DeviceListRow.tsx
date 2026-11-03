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
  const isMac = device.type === `mac`;
  const card = (
    <Card
      padding={0}
      className={cx(
        `@container/device overflow-hidden`,
        href && `group-hover:border-stone-300`,
      )}
    >
      <div
        className={cx(`flex`, isMac ? `flex-col @md/device:flex-row` : `items-center`)}
      >
        <HStack className="min-w-0 flex-1 p-3" gap={3}>
          <DeviceArtwork device={device} size="large" />
          <VStack className="min-w-0">
            <HStack gap={2} className="min-w-0">
              <Text variant="bodyLargeStrong" truncate>
                {deviceTitle(device)}
              </Text>
              {isMac && (
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
        {isMac ? (
          <div
            className={cx(
              `flex min-w-0 items-center justify-between gap-3 border-t border-stone-200 bg-stone-50/80 py-2 pl-3 pr-2`,
              `@md/device:flex-col @md/device:items-end @md/device:gap-2 @md/device:border-0 @md/device:bg-transparent @md/device:p-3 @md/device:pl-0`,
            )}
          >
            <HStack gap={2} className="min-w-0">
              <Text
                variant="captionMuted"
                truncate
                className={cx(`@md/device:max-w-44`, action && `@md/device:mr-2.25`)}
              >
                Mac user:{` `}
                <Text variant="captionStrong">{device.username}</Text>
              </Text>
              {href && (
                <ChevronRightIcon className="w-5 h-5 text-stone-400 shrink-0 group-hover:text-stone-600" />
              )}
            </HStack>
            {action && <div className="shrink-0">{action}</div>}
          </div>
        ) : (
          <HStack gap={2} className="shrink-0 pr-3">
            <Badge size="small" color="neutral">
              {device.type === `iphone` ? `iPhone` : `iPad`}
            </Badge>
            {action}
            {href && (
              <ChevronRightIcon className="w-5 h-5 text-stone-400 shrink-0 group-hover:text-stone-600" />
            )}
          </HStack>
        )}
      </div>
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
