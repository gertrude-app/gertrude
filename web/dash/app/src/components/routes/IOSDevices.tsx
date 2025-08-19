import { ApiErrorMessage, Loading, PageHeading } from '@dash/components';
import React from 'react';
import { Link } from 'react-router-dom';
import Current from '../../environment';
import { Key, useQuery } from '../../hooks';

const IOSDevices: React.FC = () => {
  const devicesQuery = useQuery(Key.iOSDevices, Current.api.iOSDevices);
  if (devicesQuery.isPending) {
    return <Loading />;
  }

  if (devicesQuery.isError) {
    return <ApiErrorMessage error={devicesQuery.error} />;
  }
  return (
    <>
      <PageHeading icon="phone" className="mb-4">
        iOS Devices
      </PageHeading>
      {devicesQuery.data.map((device) => (
        <Link to={device.id} key={device.id} className="block mb-4 p-4 border rounded-lg">
          <h2 className="text-lg font-semibold">
            {device.childName}’s {device.deviceType}
          </h2>
          <p>iOS {device.osVersion}</p>
        </Link>
      ))}
    </>
  );
};

export default IOSDevices;
