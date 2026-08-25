import { Card, HStack, Text, VStack } from '@gertrude/ui';
import { Link } from '@tanstack/react-router';
import { Clock3Icon } from 'lucide-react';
import React from 'react';
import type { MacDevice } from '#/components/devices/types';
import DeviceArtwork from '#/components/people/DeviceArtwork';

interface Props {
  device: MacDevice;
}

const MacDeviceCard: React.FC<Props> = ({ device }) => {
  const title = device.name ?? device.modelName;
  const osVersion = device.macOSVersion
    ? `macOS ${device.macOSVersion}`
    : `macOS version unavailable`;
  const subtitle = device.name ? `${device.modelName} · ${osVersion}` : osVersion;

  return (
    <Card preset="big" padding={0} className="flex flex-col overflow-hidden">
      <Card.Body padding={2.5} className="shrink-0">
        <HStack align="center" gap={2.5}>
          <div className="grid h-14 w-18 shrink-0 place-items-center">
            <DeviceArtwork device={device} size="card" />
          </div>
          <VStack className="min-w-0" gap={0.5}>
            <Text as="h3" variant="heading" lineClamp={2}>
              {title}
            </Text>
            <Text variant="bodyMuted" lineClamp={2}>
              {subtitle}
            </Text>
          </VStack>
        </HStack>
      </Card.Body>
      <Card.Footer className="flex grow flex-col px-2.5 py-2.5">
        <VStack gap={2}>
          <Text variant="label">Used by</Text>
          {device.people.length > 0 ? (
            <VStack gap={0} className="divide-y divide-stone-200">
              {device.people.map((person) => (
                <HStack
                  key={person.id}
                  align="center"
                  justify="between"
                  gap={3}
                  className="min-w-0 py-1 first:pt-0 last:pb-0"
                >
                  <Link
                    to="/people/$personId"
                    params={{ personId: person.id }}
                    className="min-w-0 truncate rounded-sm underline-offset-2 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-violet-300"
                  >
                    <Text variant="bodyStrong">{person.name}</Text>
                  </Link>
                  <HStack gap={1.5} className="shrink-0 text-stone-400">
                    <Clock3Icon className="h-3.5 w-3.5" aria-hidden="true" />
                    <Text variant="captionMuted">Filter status coming soon</Text>
                  </HStack>
                </HStack>
              ))}
            </VStack>
          ) : (
            <Text variant="bodyMuted">No protected people</Text>
          )}
        </VStack>
      </Card.Footer>
    </Card>
  );
};

export default MacDeviceCard;
