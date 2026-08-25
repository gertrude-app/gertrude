import { Badge, Card, HStack, Text, VStack } from '@gertrude/ui';
import {
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
  <Card preset="big" padding={0} className="flex flex-col overflow-hidden">
    <Card.Body
      padding={2.5}
      className={
        device.connectedApps.length === 0 || device.supervisionStatus
          ? `shrink-0 !pb-3`
          : `shrink-0`
      }
    >
      <HStack align="center" gap={2.5}>
        <div className="grid h-14 w-18 shrink-0 place-items-center">
          <DeviceArtwork device={device} size="card" />
        </div>
        <VStack className="min-w-0" gap={1.5}>
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
      </HStack>
    </Card.Body>
    <Card.Footer className="flex grow flex-col px-2.5 py-2.5">
      <VStack gap={2}>
        <Text variant="label">Connected apps</Text>
        <ConnectedAppList apps={device.connectedApps} />
      </VStack>
    </Card.Footer>
  </Card>
);

export default MobileDeviceCard;
