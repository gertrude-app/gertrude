import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import type { DevicesPageData } from '#/components/devices/types';
import type { LoadableState } from '#/components/types';
import DevicesPage from '#/components/pages/devices/DevicesPage';
import { toDevicesPageData } from '#/lib/devices';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

const DevicesRoute: React.FC = () => {
  const devicesQuery = useQuery(Key.devices, () => liveClient.getDevices());
  const state: LoadableState<DevicesPageData> =
    devicesQuery.data !== undefined
      ? { status: `success`, data: toDevicesPageData(devicesQuery.data) }
      : devicesQuery.isError
        ? {
            status: `error`,
            message:
              devicesQuery.error.userMessage ?? `Check your connection and try again.`,
            onRetry: () => void devicesQuery.refetch(),
          }
        : { status: `loading` };

  return <DevicesPage state={state} peopleHref="/people" />;
};

export const Route = createFileRoute(`/_app/devices/`)({
  component: DevicesRoute,
});
