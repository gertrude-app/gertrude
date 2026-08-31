import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import type { ConnectedIOSApp } from '#/components/devices/types';
import type { ProfileDraft } from '#/components/pages/person-settings/IosSettingsPage.reducer';
import type { IosDeviceSettingsConfiguration } from '#/components/pages/person-settings/IosSettingsPage.types';
import type { LoadableState } from '#/components/types';
import UnsavedChangesGuard from '#/components/UnsavedChangesGuard';
import IosSettingsPage from '#/components/pages/person-settings/IosSettingsPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

interface IosDeviceSettingsSearch {
  section?: ConnectedIOSApp;
}

const sections: ConnectedIOSApp[] = [`blocker`, `podcasts`, `music`];

const IosDeviceSettingsRoute: React.FC = () => {
  const { deviceId } = Route.useParams();
  const { section } = Route.useSearch();
  const [hasUnsavedChanges, setHasUnsavedChanges] = React.useState(false);
  const settingsKey = Key.iosDeviceSettings(deviceId);
  const settingsQuery = useQuery(settingsKey, () =>
    liveClient.getIosDeviceSettings({ deviceId }),
  );
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

  const state: LoadableState<IosDeviceSettingsConfiguration> =
    settingsQuery.data !== undefined
      ? { status: `success`, data: settingsQuery.data }
      : settingsQuery.isError
        ? {
            status: `error`,
            message:
              settingsQuery.error.userMessage ?? `Check your connection and try again.`,
            onRetry: () => void settingsQuery.refetch(),
          }
        : { status: `loading` };

  return (
    <>
      <IosSettingsPage
        key={deviceId}
        state={state}
        savingBlockedGroups={updateBlockedGroups.isPending}
        savingProfile={updateProfile.isPending}
        requestingPinReset={requestPinReset.isPending}
        onUnsavedChangesChange={setHasUnsavedChanges}
        defaultExpandedSection={section}
        onSaveBlockedGroups={(enabledBlockGroupIds: string[]) =>
          updateBlockedGroups
            .mutateAsync({ deviceId, enabledBlockGroupIds })
            .then(() => undefined)
        }
        onSaveProfile={(profileSettings: ProfileDraft) =>
          updateProfile
            .mutateAsync({ deviceId, ...profileSettings })
            .then(() => undefined)
        }
        onRequestPodcastsPinReset={() =>
          requestPinReset
            .mutateAsync({ deviceId })
            .then((output) => output.code)
            .catch(() => null)
        }
      />
      <UnsavedChangesGuard
        hasUnsavedChanges={hasUnsavedChanges}
        description="Your iPhone/iPad settings haven't been saved."
      />
    </>
  );
};

export const Route = createFileRoute(`/_app/people/$personId/ios-settings/$deviceId`)({
  validateSearch: (search): IosDeviceSettingsSearch => ({
    section:
      typeof search[`section`] === `string` &&
      sections.includes(search[`section`] as ConnectedIOSApp)
        ? (search[`section`] as ConnectedIOSApp)
        : undefined,
  }),
  component: IosDeviceSettingsRoute,
});
