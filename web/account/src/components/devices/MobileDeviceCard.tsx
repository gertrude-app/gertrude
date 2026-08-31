import { Badge, Card, HStack, Text, VStack } from '@gertrude/ui';
import { Link } from '@tanstack/react-router';
import {
  ChevronRightIcon,
  CircleDashedIcon,
  ShieldAlertIcon,
  ShieldCheckIcon,
  TriangleAlertIcon,
} from 'lucide-react';
import React from 'react';
import type {
  IOSDeviceSupervisionStatus,
  MobileDevice,
} from '#/components/devices/types';
import ConnectedAppList from '#/components/devices/ConnectedAppList';
import DeviceArtwork from '#/components/people/DeviceArtwork';

interface Props {
  device: MobileDevice;
}

const possessive = (name: string): string =>
  name.endsWith(`s`) ? `${name}’` : `${name}’s`;

const SupervisionBadge: React.FC<{ status: IOSDeviceSupervisionStatus }> = ({
  status,
}) => {
  switch (status) {
    case `complete`:
      return (
        <Badge size="small" color="green" icon={ShieldCheckIcon}>
          Supervised
        </Badge>
      );
    case `supervised`:
      return (
        <Badge size="small" color="yellow" icon={ShieldAlertIcon}>
          Supervised, profile pending
        </Badge>
      );
    case `claimed`:
      return (
        <Badge size="small" color="yellow" icon={CircleDashedIcon}>
          Supervision in progress
        </Badge>
      );
    case `pendingClaim`:
      return (
        <Badge size="small" color="yellow" icon={CircleDashedIcon}>
          Supervision not claimed
        </Badge>
      );
  }
};

const MobileDeviceCard: React.FC<Props> = ({ device }) => (
  <Card preset="big" padding={0} className="relative flex flex-col overflow-hidden">
    <Link
      to="/people/$personId/ios-settings/$deviceId"
      params={{ personId: device.person.id, deviceId: device.id }}
      aria-label={`Open settings for ${possessive(device.person.name)} ${device.modelName}`}
      className="peer absolute inset-0 z-10 rounded-2xl outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-violet-300"
    />
    <Card.Body
      padding={2.5}
      className={`shrink-0 transition-colors peer-hover:bg-stone-50/80 peer-focus-visible:bg-stone-50/80 ${
        device.connectedApps.length === 0 || device.supervisionStatus ? `!pb-3` : ``
      }`}
    >
      <HStack align="center" gap={2.5}>
        <div className="grid h-14 w-18 shrink-0 place-items-center">
          <DeviceArtwork device={device} size="card" />
        </div>
        <VStack className="min-w-0 flex-grow" gap={1.5}>
          <VStack gap={0.5}>
            <Text as="h3" variant="heading" lineClamp={2}>
              {possessive(device.person.name)} {device.modelName}
            </Text>
            <Text variant="bodyMuted">
              {device.type === `iphone` ? `iOS` : `iPadOS`} {device.iOSVersion}
            </Text>
          </VStack>
          {(device.connectedApps.length === 0 || device.supervisionStatus) && (
            <HStack wrap gap={1.5} className="mt-1">
              {device.connectedApps.length === 0 && (
                <Badge size="small" color="yellow" icon={TriangleAlertIcon}>
                  Setup incomplete
                </Badge>
              )}
              {device.supervisionStatus && (
                <SupervisionBadge status={device.supervisionStatus} />
              )}
            </HStack>
          )}
        </VStack>
        <ChevronRightIcon
          className="h-5 w-5 shrink-0 text-stone-400 transition-colors peer-hover:text-stone-600"
          aria-hidden="true"
        />
      </HStack>
    </Card.Body>
    <Card.Footer className="flex grow flex-col px-2.5 py-2.5">
      <VStack gap={2}>
        <Text variant="label">Connected apps</Text>
        <ConnectedAppList
          apps={device.connectedApps}
          personId={device.person.id}
          deviceId={device.id}
        />
      </VStack>
    </Card.Footer>
  </Card>
);

export default MobileDeviceCard;
