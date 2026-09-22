import React from 'react';
import type { DeviceSettingsIOSApp } from '#/components/devices/types';
import type { LoadableState } from '#/components/types';
import type { ProfileDraft } from './IosSettingsPage.reducer';
import type { IosDeviceSettingsConfiguration } from './IosSettingsPage.types';
import IosSettingsPage from './IosSettingsPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';

interface Props {
  deviceId: string;
  state: LoadableState<IosDeviceSettingsConfiguration>;
  defaultExpandedSection?: DeviceSettingsIOSApp;
  onUnsavedChangesChange?: (hasUnsavedChanges: boolean) => void;
}

const IosDeviceSettings: React.FC<Props> = ({
  deviceId,
  state,
  defaultExpandedSection,
  onUnsavedChangesChange,
}) => {
  const settingsKey = Key.iosDeviceSettings(deviceId);
  const updateBlockedGroups = useMutation(liveClient.updateIosDeviceBlockedGroups, {
    invalidating: [settingsKey],
    toast: {
      loading: `Saving blocked groups…`,
      success: `Blocked groups saved`,
      error: `Failed to save blocked groups`,
    },
  });
  const requestPinReset = useMutation(liveClient.requestPodcastsPinReset, {
    toast: {
      loading: `Generating code…`,
      success: `PIN reset code generated`,
      error: `Failed to generate PIN reset code`,
    },
  });
  const updateProfile = useMutation(liveClient.updateIosDeviceProfileSettings, {
    invalidating: [settingsKey],
    toast: {
      loading: `Saving supervision settings…`,
      success: `Supervision settings saved`,
      error: `Failed to save supervision settings`,
    },
  });

  return (
    <IosSettingsPage
      state={state}
      savingBlockedGroups={updateBlockedGroups.isPending}
      savingProfile={updateProfile.isPending}
      requestingPinReset={requestPinReset.isPending}
      onUnsavedChangesChange={onUnsavedChangesChange}
      defaultExpandedSection={defaultExpandedSection}
      onSaveBlockedGroups={(enabledBlockGroupIds: string[]) =>
        updateBlockedGroups
          .mutateAsync({ deviceId, enabledBlockGroupIds })
          .then(() => undefined)
      }
      onSaveProfile={(profileSettings: ProfileDraft) =>
        updateProfile.mutateAsync({ deviceId, ...profileSettings }).then(() => undefined)
      }
      onRequestPodcastsPinReset={() =>
        requestPinReset
          .mutateAsync({ deviceId })
          .then((output) => output.code)
          .catch(() => null)
      }
    />
  );
};

export default IosDeviceSettings;
