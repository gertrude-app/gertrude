import { EmptyState } from '@gertrude/ui';
import { createFileRoute, useLocation } from '@tanstack/react-router';
import { SmartphoneIcon } from 'lucide-react';
import React from 'react';
import type { ConnectedIOSApp } from '#/components/devices/types';
import type { MusicDeviceConnection } from '#/components/person-settings/MusicSection';
import type { LoadableState } from '#/components/types';
import type { PqlError } from '@shared/pairql';
import type { GetIosDeviceSettings, GetPeople } from '@shared/pairql/src/account';
import type { UseQueryResult } from '@tanstack/react-query';
import UnsavedChangesGuard from '#/components/UnsavedChangesGuard';
import CardContainer from '#/components/layout/CardContainer';
import IosDeviceSettings from '#/components/pages/person-settings/IosDeviceSettings';
import IosDeviceSettingsSection from '#/components/pages/person-settings/IosDeviceSettingsSection';
import IosPersonSettingsPage from '#/components/pages/person-settings/IosPersonSettingsPage';
import { validateIosSettingsSearch } from '#/lib/iosSettings';
import { toIosSettingsDevices } from '#/lib/people';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQueries, useQuery } from '#/pairql/query';

type Person = GetPeople.Output[number];
type IosDevice = ReturnType<typeof toIosSettingsDevices>[number];
type DeviceSettings = GetIosDeviceSettings.Output;
type SettingsQuery = UseQueryResult<DeviceSettings, PqlError>;

const settingsState = (query: SettingsQuery): LoadableState<DeviceSettings> =>
  query.data !== undefined
    ? { status: `success`, data: query.data }
    : query.isError
      ? {
          status: `error`,
          message: query.error.userMessage ?? `Check your connection and try again.`,
          onRetry: () => void query.refetch(),
        }
      : { status: `loading` };

interface DeviceSettingsSectionProps {
  device: IosDevice;
  state: LoadableState<DeviceSettings>;
  defaultExpandedSection?: ConnectedIOSApp;
  onUnsavedChangesChange: (deviceId: string, hasUnsavedChanges: boolean) => void;
}

const DeviceSettingsSection: React.FC<DeviceSettingsSectionProps> = ({
  device,
  state,
  defaultExpandedSection,
  onUnsavedChangesChange,
}) => {
  const reportUnsavedChanges = React.useCallback(
    (hasUnsavedChanges: boolean) => onUnsavedChangesChange(device.id, hasUnsavedChanges),
    [device.id, onUnsavedChangesChange],
  );

  return (
    <IosDeviceSettingsSection device={device}>
      <IosDeviceSettings
        deviceId={device.id}
        state={state}
        defaultExpandedSection={defaultExpandedSection}
        onUnsavedChangesChange={reportUnsavedChanges}
      />
    </IosDeviceSettingsSection>
  );
};

const IosSettingsIndexPage: React.FC<{ person: Person }> = ({ person }) => {
  const { section } = Route.useSearch();
  const { hash } = useLocation();
  const devices = toIosSettingsDevices(person);
  const settingsQueries = useQueries(
    devices.map((device) => ({
      key: Key.iosDeviceSettings(device.id),
      fn: () => liveClient.getIosDeviceSettings({ deviceId: device.id }),
    })),
  );
  const deviceQueries = devices.flatMap((device, index) => {
    const query = settingsQueries[index];
    return query ? [{ device, query }] : [];
  });
  const [unsavedDeviceIds, setUnsavedDeviceIds] = React.useState<Set<string>>(
    () => new Set(),
  );
  const updateUnsavedChanges = React.useCallback(
    (deviceId: string, hasUnsavedChanges: boolean) => {
      setUnsavedDeviceIds((current) => {
        if (current.has(deviceId) === hasUnsavedChanges) return current;
        const next = new Set(current);
        if (hasUnsavedChanges) {
          next.add(deviceId);
        } else {
          next.delete(deviceId);
        }
        return next;
      });
    },
    [],
  );

  const targetHash = section === `music` ? `music` : hash;
  React.useEffect(() => {
    if (!targetHash) return;
    const frame = requestAnimationFrame(() => {
      document.getElementById(targetHash)?.scrollIntoView({ block: `start` });
    });
    return () => cancelAnimationFrame(frame);
  }, [devices.length, targetHash]);

  if (devices.length === 0) {
    return (
      <CardContainer>
        <EmptyState
          icon={SmartphoneIcon}
          title="No iPhone or iPad connected"
          description={`Connect Gertrude Blocker, Podcasts, or Music on an iPhone or iPad to manage ${person.name}’s settings here.`}
          className="bg-white"
        />
      </CardContainer>
    );
  }

  const failedQuery = settingsQueries.find((query) => query.isError);
  const musicState: LoadableState<MusicDeviceConnection[]> = failedQuery
    ? {
        status: `error`,
        message: failedQuery.error.userMessage ?? `Check your connection and try again.`,
        onRetry: () => settingsQueries.forEach((query) => void query.refetch()),
      }
    : deviceQueries.length !== devices.length ||
        deviceQueries.some(({ query }) => query.data === undefined)
      ? { status: `loading` }
      : {
          status: `success`,
          data: deviceQueries.flatMap(({ device, query }) =>
            query.data?.music ? [{ device, music: query.data.music }] : [],
          ),
        };

  return (
    <>
      <IosPersonSettingsPage
        personName={person.name}
        musicState={musicState}
        defaultExpandedMusic={section === `music`}
      >
        {deviceQueries.map(({ device, query }) => (
          <DeviceSettingsSection
            key={device.id}
            device={device}
            state={settingsState(query)}
            defaultExpandedSection={hash === device.id ? section : undefined}
            onUnsavedChangesChange={updateUnsavedChanges}
          />
        ))}
      </IosPersonSettingsPage>
      <UnsavedChangesGuard
        hasUnsavedChanges={unsavedDeviceIds.size > 0}
        description="Your iPhone/iPad settings haven't been saved."
      />
    </>
  );
};

const IosSettingsIndexRoute: React.FC = () => {
  const { personId } = Route.useParams();
  const query = useQuery(Key.people, () => liveClient.getPeople());
  const person = query.data?.find(
    (candidate) => candidate.id.toLowerCase() === personId.toLowerCase(),
  );

  // the person route above already renders loading/error/not-found states
  if (!person) {
    return null;
  }

  return <IosSettingsIndexPage person={person} />;
};

export const Route = createFileRoute(`/_app/people/$personId/ios-settings/`)({
  validateSearch: validateIosSettingsSearch,
  component: IosSettingsIndexRoute,
});
