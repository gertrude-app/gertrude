import { ApiErrorMessage, EditComputer, Loading } from '@dash/components';
import React, { useState } from 'react';
import { useParams } from 'react-router-dom';
import type { ReleaseChannel } from '@dash/types';
import { Key, useMutation, useQuery, useZip } from '../../hooks';
import Current from '../../environment';

const Computer: React.FC = () => {
  const { computerId: id = `` } = useParams<{ computerId: string }>();

  const getComputer = useQuery(Key.device(id), () => Current.api.getDevice(id), {
    onReceive: (data) => {
      setName(data.name || ``);
      setReleaseChannel(data.releaseChannel);
    },
  });
  const latestAppVersions = useQuery(Key.latestAppVersions, () =>
    Current.api.latestAppVersions(),
  );
  const saveComputer = useMutation(
    () =>
      Current.api.saveDevice({
        id,
        name: name.trim() || undefined,
        releaseChannel: releaseChannel,
      }),
    {
      invalidating: [Key.device(id)],
      toast: `save:computer`,
    },
  );

  const [name, setName] = useState(``);
  const [releaseChannel, setReleaseChannel] = useState<ReleaseChannel>(`stable`);

  const zip = useZip(getComputer, latestAppVersions);
  if (zip.isLoading) return <Loading />;
  if (zip.isError) return <ApiErrorMessage error={zip.error} />;
  const [deviceData, appVersionsData] = zip.data;

  return (
    <EditComputer
      name={name}
      setName={setName}
      releaseChannel={releaseChannel}
      setReleaseChannel={setReleaseChannel}
      modelTitle={deviceData.modelTitle}
      serialNumber={deviceData.serialNumber}
      modelIdentifier={deviceData.modelIdentifier}
      appVersion={deviceData.appVersion}
      latestReleaseVersion={appVersionsData[releaseChannel]}
      users={deviceData.users}
      saveButtonDisabled={
        releaseChannel === deviceData.releaseChannel &&
        name.trim() === (deviceData.name ?? ``).trim()
      }
      onSave={() => saveComputer.mutate({})}
    />
  );
};

export default Computer;
