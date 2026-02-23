import { ApiErrorMessage, ChildIOSDevices, Loading } from '@dash/components';
import React from 'react';
import { useParams } from 'react-router-dom';
import Current from '../../environment';
import { Key, useMutation, useQuery } from '../../hooks';
import ReqState from '../../lib/ReqState';

const ChildIOSDevicesRoute: React.FC = () => {
  const { userId: id = `` } = useParams<{ userId: string }>();

  const query = useQuery(Key.child(id), () => Current.api.getChild(id));

  const addDevice = useMutation((childId: UUID) =>
    Current.api.iOSAppConnectionCode({ childId }),
  );

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return (
    <ChildIOSDevices
      childId={id}
      childName={query.data.name}
      iosDevices={query.data.iosDevices}
      startAddDevice={() => addDevice.mutate(id)}
      dismissAddDevice={() => addDevice.reset()}
      addDeviceRequest={ReqState.fromMutation(addDevice)}
    />
  );
};

export default ChildIOSDevicesRoute;
