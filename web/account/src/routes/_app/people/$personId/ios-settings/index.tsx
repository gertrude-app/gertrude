import { EmptyState } from '@gertrude/ui';
import { Navigate, createFileRoute } from '@tanstack/react-router';
import { SmartphoneIcon } from 'lucide-react';
import React from 'react';
import type { Device } from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import IosDevicePicker from '#/components/person-settings/IosDevicePicker';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

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

  const devices: Device[] = person.devices.flatMap((device) =>
    device.case === `ios` && device.blockerConnected
      ? [
          {
            id: device.id,
            personId: person.id,
            type: device.type,
            iOSVersion: device.iOSVersion,
            modelName: device.modelName,
            modelIdentifier: device.modelIdentifier,
          },
        ]
      : [],
  );

  if (devices.length === 0) {
    return (
      <CardContainer>
        <EmptyState
          icon={SmartphoneIcon}
          title="No iPhone or iPad connected"
          description={`Connect the Gertrude Blocker app on an iPhone or iPad to manage ${person.name}’s settings here.`}
          className="bg-white"
        />
      </CardContainer>
    );
  }

  if (devices.length === 1 && devices[0]) {
    return (
      <Navigate
        to="/people/$personId/ios-settings/$deviceId"
        params={{ personId, deviceId: devices[0].id }}
        replace
      />
    );
  }

  return (
    <CardContainer>
      <IosDevicePicker
        devices={devices}
        hrefForDevice={(deviceId) => `/people/${personId}/ios-settings/${deviceId}`}
      />
    </CardContainer>
  );
};

export const Route = createFileRoute(`/_app/people/$personId/ios-settings/`)({
  component: IosSettingsIndexRoute,
});
