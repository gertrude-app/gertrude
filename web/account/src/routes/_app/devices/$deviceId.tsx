import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import type { MacDeviceDetails, ReleaseChannel } from '#/components/devices/types';
import type { LoadableState } from '#/components/types';
import UnsavedChangesGuard from '#/components/UnsavedChangesGuard';
import MacDevicePage from '#/components/pages/devices/MacDevicePage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

const MacDeviceRoute: React.FC = () => {
  const { deviceId } = Route.useParams();
  const queryKey = Key.macDevice(deviceId);
  const query = useQuery(queryKey, () => liveClient.getMacDevice({ deviceId }));
  const device = query.data;
  const [nameDraft, setNameDraft] = React.useState(``);
  const [releaseChannelDraft, setReleaseChannelDraft] =
    React.useState<ReleaseChannel>(`stable`);
  const draftDeviceId = React.useRef<string | undefined>(undefined);
  const hasUnsavedChanges =
    device !== undefined &&
    draftDeviceId.current === device.id &&
    (nameDraft.trim() !== (device.name ?? ``) ||
      releaseChannelDraft !== device.releaseChannel);
  const updateDevice = useMutation(liveClient.updateMacDevice, {
    invalidating: [queryKey, Key.devices, Key.people],
    toast: {
      loading: `Saving Mac details…`,
      success: `Mac details saved`,
      error: `Failed to save Mac details`,
    },
  });

  React.useEffect(() => {
    if (
      device !== undefined &&
      (draftDeviceId.current !== device.id || !hasUnsavedChanges)
    ) {
      draftDeviceId.current = device.id;
      setNameDraft(device.name ?? ``);
      setReleaseChannelDraft(device.releaseChannel);
    }
  }, [device, hasUnsavedChanges]);

  const state: LoadableState<MacDeviceDetails> =
    device !== undefined
      ? { status: `success`, data: device }
      : query.isError
        ? {
            status: `error`,
            message:
              query.error.userMessage ??
              (query.error.type === `notFound`
                ? `This Mac may have been disconnected or belong to another account.`
                : `Check your connection and try again.`),
            onRetry: () => void query.refetch(),
          }
        : { status: `loading` };

  return (
    <>
      <MacDevicePage
        state={state}
        nameDraft={nameDraft}
        setNameDraft={setNameDraft}
        releaseChannelDraft={releaseChannelDraft}
        setReleaseChannelDraft={setReleaseChannelDraft}
        saving={updateDevice.isPending}
        onSave={() =>
          updateDevice.mutate({
            deviceId,
            name: nameDraft.trim() || undefined,
            releaseChannel: releaseChannelDraft,
          })
        }
      />
      <UnsavedChangesGuard
        hasUnsavedChanges={hasUnsavedChanges}
        description="Your Mac details haven't been saved."
      />
    </>
  );
};

export const Route = createFileRoute(`/_app/devices/$deviceId`)({
  component: MacDeviceRoute,
});
