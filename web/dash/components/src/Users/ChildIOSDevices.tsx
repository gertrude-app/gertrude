import { Button } from '@shared/components';
import { posessive } from '@shared/string';
import React from 'react';
import type { ChildIOSDevice, IOSAppConnectionCode, RequestState } from '@dash/types';
import EmptyState from '../EmptyState';
import PageHeading from '../PageHeading';
import ConnectIOSAppModal from './ConnectIOSAppModal';
import DeviceCard from './DeviceCard';

interface Props {
  childId: string;
  childName: string;
  iosDevices: ChildIOSDevice[];
  startAddDevice(): unknown;
  dismissAddDevice(): unknown;
  addDeviceRequest?: RequestState<IOSAppConnectionCode.Output>;
}

const ChildIOSDevices: React.FC<Props> = ({
  childId,
  childName,
  iosDevices,
  startAddDevice,
  dismissAddDevice,
  addDeviceRequest,
}) => (
  <div className="relative max-w-3xl">
    <ConnectIOSAppModal
      request={addDeviceRequest}
      dismissModal={dismissAddDevice}
      childName={childName}
    />
    <PageHeading icon="phone">{posessive(childName)} Devices</PageHeading>
    {iosDevices.length === 0 ? (
      <EmptyState
        heading="No devices yet"
        secondaryText={`Download the \u201cGertrude Blocker\u201d app from an iPhone or iPad, and enter a connection code from the button below when prompted.`}
        icon="mobile-screen"
        buttonText="Connection code"
        buttonIcon="link"
        action={startAddDevice}
        className="mt-8"
      />
    ) : (
      <div className="flex flex-col mt-8 -mx-2 xs:mx-0">
        {iosDevices.map((device) => (
          <div key={device.id} className="flex items-center mt-3 first:mt-0">
            <DeviceCard
              to={
                device.pendingClaimCode === undefined
                  ? `/children/${childId}/ios-devices/${device.id}`
                  : `/supervise-device/${device.pendingClaimCode}/download-helper`
              }
              imageSrc={`/ios/${device.deviceType}.png`}
              imageAlt={device.modelName}
              title={device.modelName}
              subtitle={device.iosVersion}
              status={
                device.pendingClaimCode !== undefined
                  ? { case: `pendingSetup` }
                  : undefined
              }
              className="flex-grow"
            />
          </div>
        ))}
        <Button
          type="button"
          onClick={startAddDevice}
          color="secondary"
          size="medium"
          className="self-end mt-4"
        >
          <i className="fa fa-plus mr-2" />
          Add a device
        </Button>
      </div>
    )}
  </div>
);

export default ChildIOSDevices;
