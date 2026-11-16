import { Badge, Card, HStack, Text, VStack } from '@gertrude/ui';
import { Link } from '@tanstack/react-router';
import cx from 'clsx';
import { ChevronRightIcon } from 'lucide-react';
import React from 'react';
import type { Device } from '#/components/types';
import { MacStatusBadge } from '#/components/devices/MacPersonStatus';
import DeviceArtwork from '#/components/people/DeviceArtwork';
import { deviceSubtitle, deviceTitle } from '#/components/utils';

export const DeviceLink: React.FC<{ device: Device }> = ({ device }) => {
  const className = `absolute inset-0 z-10 rounded-[inherit] outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-violet-300`;
  const label = `Open ${deviceTitle(device)}`;
  return device.type === `mac` ? (
    <Link
      to="/devices/$deviceId"
      params={{ deviceId: device.computerId }}
      aria-label={label}
      className={className}
    />
  ) : (
    <Link
      to="/people/$personId/ios-settings"
      params={{ personId: device.personId }}
      hash={device.id}
      aria-label={label}
      className={className}
    />
  );
};

interface Props {
  device: Device;
  linked?: boolean;
  action?: React.ReactNode;
}

const DeviceListRow: React.FC<Props> = ({ device, linked = false, action }) => {
  const isMac = device.type === `mac`;
  return (
    <Card
      padding={0}
      className={cx(
        `group relative @container/device overflow-hidden`,
        linked && `hover:border-stone-300`,
      )}
    >
      {linked && <DeviceLink device={device} />}
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
              {isMac && <MacStatusBadge status={device.status} size="xsmall" />}
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
              {linked && (
                <ChevronRightIcon className="w-5 h-5 text-stone-400 shrink-0 group-hover:text-stone-600" />
              )}
            </HStack>
            {action && <div className="relative z-20 shrink-0">{action}</div>}
          </div>
        ) : (
          <HStack gap={2} className="shrink-0 pr-3">
            <Badge size="small" color="neutral">
              {device.type === `iphone` ? `iPhone` : `iPad`}
            </Badge>
            {action && <div className="relative z-20">{action}</div>}
            {linked && (
              <ChevronRightIcon className="w-5 h-5 text-stone-400 shrink-0 group-hover:text-stone-600" />
            )}
          </HStack>
        )}
      </div>
    </Card>
  );
};

export default DeviceListRow;
