import { Text, VStack } from '@gertrude/ui';
import React from 'react';
import type { Device } from '#/components/types';
import DeviceListRow from '#/components/people/DeviceListRow';

interface Props {
  devices: Device[];
  hrefForDevice: (deviceId: string) => string;
}

const IosDevicePicker: React.FC<Props> = ({ devices, hrefForDevice }) => (
  <VStack gap={3}>
    <VStack>
      <Text variant="bodyStrong">Choose a device</Text>
      <Text variant="bodySubtle">
        Gertrude Blocker settings are configured separately for each iPhone and iPad.
      </Text>
    </VStack>
    <VStack gap={2}>
      {devices.map((device) => (
        <DeviceListRow key={device.id} device={device} href={hrefForDevice(device.id)} />
      ))}
    </VStack>
  </VStack>
);

export default IosDevicePicker;
