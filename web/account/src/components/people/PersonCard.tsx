import {
  Badge,
  Button,
  Card,
  EmptyState,
  HStack,
  Stack,
  Text,
  VStack,
} from '@gertrude/ui';
import { MonitorSmartphoneIcon, PlusIcon, ScanEyeIcon, SettingsIcon } from 'lucide-react';
import React from 'react';
import type { Device, PersonCardPerson } from '#/components/types';
import DeviceArtwork from '#/components/people/DeviceArtwork';
import { deviceSubtitle, deviceTitle } from '#/components/utils';

interface Props {
  person: PersonCardPerson;
  settingsHref?: string;
  monitorHref?: string;
  addDeviceHref?: string;
}

const PersonCard: React.FC<Props> = ({
  person,
  settingsHref,
  monitorHref,
  addDeviceHref,
}) => {
  const canMonitor =
    monitorHref !== undefined && person.devices.some((device) => device.type === `mac`);
  const hasActions = settingsHref !== undefined || canMonitor;

  return (
    <Card preset="big" padding={0}>
      <Card.Body padding={{ default: 3, '@lg/main': 4 }}>
        <Stack direction={{ default: `vertical`, '@2xl/main': `horizontal` }} gap={3}>
          <VStack gap={3} className={person.screenshot ? `@2xl/main:w-1/2` : `w-full`}>
            <Text variant="heading">{person.name}</Text>
            {person.devices.length > 0 ? (
              <VStack gap={2}>
                {person.devices.map((device) => (
                  <DeviceRow key={device.id} device={device} />
                ))}
              </VStack>
            ) : (
              <EmptyState
                icon={MonitorSmartphoneIcon}
                title="No Devices"
                description={`Add a device to get started protecting ${person.name}.`}
                button={
                  addDeviceHref
                    ? {
                        text: `Add Device`,
                        type: `link`,
                        href: addDeviceHref,
                        icon: PlusIcon,
                        variant: `primary`,
                      }
                    : undefined
                }
              />
            )}
          </VStack>
          {person.screenshot && (
            <VStack
              justify="center"
              align="center"
              gap={2}
              className="@2xl/main:w-1/2 p-4 h-[100%]"
            >
              <div className="relative">
                <img
                  src={person.screenshot.url}
                  alt=""
                  aria-hidden="true"
                  className="rounded absolute blur-[10px] opacity-50"
                />
                <img
                  src={person.screenshot.url}
                  alt={`${person.name}'s recent screenshot`}
                  className="rounded relative"
                />
              </div>
              <Text variant="caption">{person.screenshot.recency}</Text>
            </VStack>
          )}
        </Stack>
      </Card.Body>
      {hasActions && (
        <Card.Footer className="flex justify-end @lg/main:px-4">
          <HStack gap={2}>
            {settingsHref && (
              <Button type="link" href={settingsHref} icon={SettingsIcon} variant="ghost">
                Settings
              </Button>
            )}
            {canMonitor && (
              <Button type="link" href={monitorHref} icon={ScanEyeIcon}>
                Monitor
              </Button>
            )}
          </HStack>
        </Card.Footer>
      )}
    </Card>
  );
};

interface DeviceRowProps {
  device: Device;
}

const DeviceRow: React.FC<DeviceRowProps> = ({ device }) => (
  <Card variant="subtle" padding={0}>
    <HStack align="center" gap={2.5} className="py-1.5 pl-2.5 pr-4">
      <DeviceArtwork device={device} />
      <VStack className="flex-grow">
        <Text variant="bodyStrong">{deviceTitle(device)}</Text>
        <Text variant="captionMuted">{deviceSubtitle(device)}</Text>
      </VStack>
      {device.type === `mac` && (
        <Badge size="small" color={device.online ? `green` : `neutral`}>
          {device.online ? `Online` : `Offline`}
        </Badge>
      )}
    </HStack>
  </Card>
);

export default PersonCard;
