import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import type {
  InstalledMacApp,
  MacMonitoringConfiguration,
  MacSettingsConfiguration,
} from '#/components/pages/person-settings/MacSettingsPage.types';
import type { LoadableState } from '#/components/types';
import UnsavedChangesGuard from '#/components/UnsavedChangesGuard';
import MacSettingsPage from '#/components/pages/person-settings/MacSettingsPage';
import { apiEndpoint, liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

const MacSettingsRoute: React.FC = () => {
  const { personId } = Route.useParams();
  const [hasUnsavedChanges, setHasUnsavedChanges] = React.useState(false);
  const settingsKey = Key.personMacSettings(personId);
  const settingsQuery = useQuery(settingsKey, () =>
    liveClient.getPersonMacSettings({ personId }),
  );
  const installedAppsQuery = useQuery(Key.personInstalledMacApps(personId), () =>
    liveClient.getPersonInstalledMacApps({ personId }),
  );
  const updateMonitoring = useMutation(liveClient.updatePersonMacMonitoringSettings, {
    invalidating: [settingsKey, Key.activity],
    toast: {
      loading: `Saving monitoring settings…`,
      success: `Monitoring settings saved`,
      error: `Failed to save monitoring settings`,
    },
  });
  const updateInternetFiltering = useMutation(
    liveClient.updatePersonMacInternetFiltering,
    {
      invalidating: [settingsKey],
      toast: {
        loading: `Saving internet filtering settings…`,
        success: `Internet filtering settings saved`,
        error: `Failed to save internet filtering settings`,
      },
    },
  );
  const updateApps = useMutation(liveClient.updatePersonMacApps, {
    invalidating: [settingsKey],
    toast: {
      loading: `Saving app settings…`,
      success: `App settings saved`,
      error: `Failed to save app settings`,
    },
  });
  const requestPublicKeychain = useMutation(liveClient.requestAccountPublicKeychain);
  const installedApps: InstalledMacApp[] =
    installedAppsQuery.data?.map((app) => ({
      id: app.bundleId,
      name: app.name,
      bundleId: app.bundleId,
      identifiedAppSlug: app.identifiedAppSlug,
      appIconUrl: app.iconHash ? `${apiEndpoint}/app-icon/${app.iconHash}` : undefined,
    })) ?? [];

  const state: LoadableState<MacSettingsConfiguration> =
    settingsQuery.data !== undefined
      ? { status: `success`, data: settingsQuery.data }
      : settingsQuery.isError
        ? {
            status: `error`,
            message:
              settingsQuery.error.userMessage ?? `Check your connection and try again.`,
            onRetry: () => {
              void settingsQuery.refetch();
              void installedAppsQuery.refetch();
            },
          }
        : { status: `loading` };

  return (
    <>
      <MacSettingsPage
        key={personId}
        state={state}
        installedApps={installedApps}
        savingMonitoring={updateMonitoring.isPending}
        savingInternetFiltering={updateInternetFiltering.isPending}
        savingApps={updateApps.isPending}
        onUnsavedChangesChange={setHasUnsavedChanges}
        onSaveMonitoring={(configuration: MacMonitoringConfiguration) =>
          updateMonitoring
            .mutateAsync({
              personId,
              keyloggingEnabled: configuration.keyloggingEnabled,
              showSuspensionActivity: configuration.showSuspensionActivity,
              screenshotsEnabled: configuration.screenshots.enabled,
              screenshotsResolution: configuration.screenshots.resolution,
              screenshotsFrequency: configuration.screenshots.frequency,
            })
            .then(() => undefined)
        }
        onSaveApps={({ blockedApps, unrestrictedApps }) =>
          updateApps
            .mutateAsync({ personId, blockedApps, unrestrictedApps })
            .then(() => undefined)
        }
        onRequestPublicKeychain={(input) =>
          requestPublicKeychain.mutateAsync(input).then(() => undefined)
        }
        onSaveInternetFiltering={({
          filteringEnabled,
          downtime,
          keychains,
          alwaysBlockedGroupIds,
          customAlwaysBlockedRules,
        }) =>
          updateInternetFiltering
            .mutateAsync({
              personId,
              filteringEnabled,
              downtime,
              keychains,
              alwaysBlockedGroupIds,
              customAlwaysBlockedRules,
            })
            .then(() => undefined)
        }
      />
      <UnsavedChangesGuard
        hasUnsavedChanges={hasUnsavedChanges}
        description="Your Mac settings haven't been saved."
      />
    </>
  );
};

export const Route = createFileRoute(`/_app/people/$personId/mac-settings`)({
  component: MacSettingsRoute,
});
